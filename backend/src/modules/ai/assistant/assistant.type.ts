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
  generate(contents: Content[], declarations: Declaration[], signal: AbortSignal, onText?: (text: string) => void): Promise<Content>;
  embed(text: string, signal: AbortSignal): Promise<number[]>;
  embeddingModel: string;
}
export type ListingCard = { id: string; title: string; price: string; areaLabel: string };
export type Source = { id: string; title: string; text: string };
export type AssistantReply = { text: string; listings: ListingCard[]; sources: Source[] };
export type AssistantEvent = { type: 'status'; stage: 'thinking' | 'searching_listings' | 'reading_listings' | 'searching_knowledge' | 'reading_quota' } | { type: 'delta'; text: string } | { type: 'reset' };
