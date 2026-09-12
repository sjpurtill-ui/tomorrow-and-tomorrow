# Research collection capacity and access

Collections, evidence references and acquisition origins now permit up to 32,768 records instead of 1,024. This provides room for multiple acquisition records across the 5,000-discovery target. It does not create discoveries or evidence. Contact and outbound-household record limits remain 1,024; other existing mission and migration bounds remain.

The collection view displays forty matching records per page, with Previous/Next controls and a page count. Filtering resets the page, shrinking results clamp it, and equal return dates sort by record ID for deterministic ordering. Older finds remain accessible instead of disappearing behind the newest forty. No records are deleted or consolidated.

Study still draws 15% of existing Knowledge work. The loop now stops once that day's work is exhausted, retaining the same insertion-order study priority. Fully studied records remain in the saved collection. Long-term indexing, archive compaction, study priority controls and maximum-capacity performance measurements remain unfinished; 32,768-record capacity is not a claim of 32,768-record performance validation. This remains a finite cap rather than an unlimited archive.

Existing save shapes and records remain valid. Older builds reject collections beyond their former limit. A test uses 5,001 synthetic collection records to exercise serialization and evidence references; these fixtures are not authored production discoveries and do not change the live catalog count.
