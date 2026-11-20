export type Part = {
  text?: string;
  thought?: boolean;
  thoughtSignature?: string;
  functionCall?: { id?: string; name: string; args: unknown };
  functionResponse?: { id?: string; name: string; response: unknown };
};
export type Content = { role: 'user' | 'model'; parts: Part[] };
export type Declaration = { name: string; description: string; parametersJsonSchema: unknown };
export interface AiProvider {
  extractNeeds?(input: unknown, signal: AbortSignal): Promise<unknown>;
  verifyGrounding?(input: { question: string; answer: string; evidence: unknown }, signal: AbortSignal): Promise<boolean>;
  generate(contents: Content[], declarations: Declaration[], signal: AbortSignal, onText?: (text: string) => void): Promise<Content>;
  embed(text: string, signal: AbortSignal): Promise<number[]>;
  embeddingModel: string;
}
export type ListingCard = { id: string; title: string; price: string; areaLabel: string };
export type Source = { id: string; title: string; text: string };
export type DraftProposal = { id: string; title: string; description: string; price: string };
export type AssistantReply = { text: string; listings: ListingCard[]; sources: Source[]; draft?: DraftProposal; suggestions?: string[] };
export type AssistantEvent = { type: 'status'; stage: 'thinking' | 'searching_listings' | 'reading_listings' | 'searching_knowledge' | 'reading_quota' | 'preparing_draft' } | { type: 'delta'; text: string } | { type: 'reset' };
