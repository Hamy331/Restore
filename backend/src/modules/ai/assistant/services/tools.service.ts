import { z } from 'zod';
import { AppError } from '../../../../common/errors/app-error.js';
import { parse } from '../../../../common/validation/schemas.js';
import { searchListings } from './listing-search.service.js';
import { findVisible } from '../../../listings/repositories/listing.repository.js';
import { toListingDto } from '../../../listings/listing.dto.js';
import { getMyStore } from '../../../commerce/services/store.service.js';
import { retrieve } from '../../rag/services/rag.service.js';
import { detailsArgs, knowledgeArgs, noArgs, searchArgs } from '../assistant.validator.js';
import type { AiProvider, AssistantReply, Declaration, DraftProposal, ListingCard } from '../assistant.type.js';
import { redactValue } from '../../../../common/security/redaction.js';
import { containsInstruction } from './input-guard.service.js';

const definitions = [
  { name: 'search_listings', description: 'Hybrid semantic and keyword search of available listings. Supply natural-language q plus separate brand, categoryId and VND price filters, including constraints from prior turns.', schema: searchArgs },
  { name: 'listing_details', description: 'Read up to three public listings by IDs returned by search, to compare current details.', schema: detailsArgs },
  { name: 'my_quota', description: 'Read the signed-in user current plan, usage and remaining listing/draft quotas.', schema: noArgs },
  { name: 'search_knowledge', description: 'Retrieve approved ReStore documentation. Empty sources means insufficient evidence; do not invent policy.', schema: knowledgeArgs },
] as const;

export const declarations: Declaration[] = definitions.map(({ name, description, schema }) => {
  const { $schema: _, ...parametersJsonSchema } = z.toJSONSchema(schema);
  return { name, description, parametersJsonSchema };
});

export function validateTool(name: string, args: unknown) {
  const tool = definitions.find((item) => item.name === name);
  if (!tool) throw new AppError(400, 'AI_TOOL_NOT_ALLOWED', 'Công cụ không được phép.');
  return parse(tool.schema, args);
}

export class ToolSession {
  readonly reply: AssistantReply = { text: '', listings: [], sources: [] };
  proposal?: DraftProposal;
  constructor(private readonly userId: string, private readonly provider: AiProvider, private readonly signal: AbortSignal) {}

  async execute(name: string, args: unknown): Promise<unknown> {
    validateTool(name, args);
    switch (name) {
      case 'search_listings': {
        const input = parse(searchArgs, args);
        const items = await searchListings(input, this.provider, this.signal);
        this.reply.listings = redactValue(items.filter(item => !containsInstruction(item.title)).map(({ id, title, price, areaLabel }) => ({ id, title, price, areaLabel })));
        return { items: this.reply.listings, returned: items.length, mode: 'hybrid', instruction: 'These are matching indexed listings, not a complete inventory. Do not infer that no listings exist from an empty result.' };
      }
      case 'listing_details': {
        const { ids } = parse(detailsArgs, args);
        const items = [];
        for (const id of ids) {
          const listing = await findVisible(id);
          if (!listing) continue;
          const dto = toListingDto(listing);
          if (containsInstruction(dto.title) || containsInstruction(dto.description) || containsInstruction(JSON.stringify(dto.attributes))) continue;
          const card: ListingCard = { id: dto.id, title: dto.title, price: dto.price, areaLabel: dto.areaLabel };
          this.reply.listings = [...this.reply.listings.filter((item) => item.id !== id), card].slice(-5);
          items.push(redactValue({ ...card, description: dto.description, condition: dto.condition, attributes: dto.attributes }));
        }
        return { items };
      }
      case 'my_quota': {
        const { package: plan, usage, remaining, endsAt } = await getMyStore(this.userId);
        return { plan: { name: plan.name, tier: plan.tier }, usage, remaining, endsAt, creditsSupported: false };
      }
      case 'search_knowledge': {
        this.reply.sources = redactValue((await retrieve(parse(knowledgeArgs, args).query, this.provider, this.signal))
          .filter(source => !containsInstruction(source.title + '\n' + source.text)));
        return { sources: this.reply.sources, instruction: 'Use only these excerpts as evidence; no matching sources means policy is unknown.' };
      }

    }
  }
}
