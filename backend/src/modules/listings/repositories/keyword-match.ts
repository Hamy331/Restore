import { Prisma } from '@prisma/client';

/*
 * So từ khoá tìm kiếm với nội dung trong SQL, dùng chung cho tìm tin (feed.repository) và gợi ý khi gõ
 * (search.repository): so nguyên từ, gõ có dấu thì so đúng dấu.
 */

/**
 * Biểu thức SQL [column] chữ thường, bỏ dấu tiếng Việt (kể cả đ), để so với từ khoá đã qua normalizeTitle.
 * Chưa có index: tính trên từng tin đang hiển thị, đủ nhanh với vài chục nghìn tin.
 */
// ponytail: full scan on folded text; past ~50k listings add a stored folded column + pg_trgm GIN index and match with LIKE.
export const foldedText = (column: Prisma.Sql) =>
  Prisma.sql`replace(regexp_replace(normalize(lower(${column}), NFD), ${'[̀-ͯ]'}, '', 'g'), 'đ', 'd')`;

/** Tách [text] thành các từ cách nhau một khoảng trắng, đệm khoảng trắng hai đầu để so nguyên từ */
export const tokens = (text: Prisma.Sql) => Prisma.sql`(' ' || regexp_replace(${text}, '[^[:alnum:]]+', ' ', 'g') || ' ')`;
/** Chữ thường, bỏ dấu: so với từ khoá gõ không dấu */
export const folded = (text: Prisma.Sql) => tokens(foldedText(text));
/** Chữ thường, giữ dấu: so với từ khoá gõ có dấu ("cộ" không khớp "có") */
export const accented = (text: Prisma.Sql) => tokens(Prisma.sql`normalize(lower(${text}), NFC)`);

/** Một từ khoá: [exact] khi người dùng gõ có dấu thì so trên nội dung giữ dấu */
export type SearchTerm = { text: string; exact: boolean };
export const searchTerms = ({ words, exactWords }: { words: string[]; exactWords?: string[] }): SearchTerm[] =>
  words.map((word, index) => {
    const exact = exactWords?.length === words.length ? exactWords[index] : word;
    return exact !== word ? { text: exact, exact: true } : { text: word, exact: false };
  });

/**
 * So nguyên từ: từ ngắn (dưới 3 ký tự) phải trùng cả từ ("co" không khớp "corgi"), từ dài hơn được khớp
 * đầu từ ("iphon" khớp "iphone").
 */
const termIn = ({ text, exact }: SearchTerm, foldedColumn: Prisma.Sql, accentedColumn: Prisma.Sql) =>
  Prisma.sql`POSITION(${text.length < 3 ? ` ${text} ` : ` ${text}`} IN ${exact ? accentedColumn : foldedColumn}) > 0`;

export const allTermsIn = (terms: SearchTerm[], foldedColumn: Prisma.Sql, accentedColumn: Prisma.Sql) =>
  Prisma.join(terms.map((term) => termIn(term, foldedColumn, accentedColumn)), ' AND ', '(', ')');
