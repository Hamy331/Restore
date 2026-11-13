-- Thú cưng không hỏi tình trạng hàng; tuổi nhập được theo tháng hoặc năm (lưu vẫn là số tháng)
UPDATE "Category"
SET "metadata" = jsonb_set(
  "metadata" || '{"hasCondition": false}'::jsonb,
  '{attributes}',
  COALESCE((
    SELECT jsonb_agg(
      CASE WHEN attribute->>'key' = 'age_months'
        THEN attribute || '{"unitOptions": [{"value": "month", "label": {"vi": "tháng", "en": "months"}, "factor": 1}, {"value": "year", "label": {"vi": "năm", "en": "years"}, "factor": 12}]}'::jsonb
        ELSE attribute END
      ORDER BY position)
    FROM jsonb_array_elements("metadata"->'attributes') WITH ORDINALITY AS item(attribute, position)
  ), '[]'::jsonb)
)
WHERE "id" = 'pets';

-- Tin thú cưng cũ bỏ tình trạng
UPDATE "Listing" SET "condition" = NULL WHERE "categoryId" = 'pets';
