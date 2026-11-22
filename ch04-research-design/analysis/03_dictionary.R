# Step 3. The attainable bar: a dictionary rule for achievement imagery.
#
# A rule scores a sentence for achievement if at least `k` of its words belong
# to a chosen subset of the six General Inquirer categories. Every subset, both
# ways of matching, and k = 1, 2, 3 are tried on the development sentences, and
# the rule with the highest agreement is kept. Because it is chosen on these
# sentences, its figure here flatters it. Its test is the reserved material.

source("R/setup.R")

stories <- read_stories(labels = TRUE) |>
  filter(role == "development")

counts <- list(
  stems = category_counts(stories$text, stem = TRUE),
  exact = category_counts(stories$text, stem = FALSE)
)

# Every rule, with its agreement on the development sentences ------------------

subsets <- map(seq_along(inquirer_categories), \(n) {
  combn(inquirer_categories, n, simplify = FALSE)
}) |>
  list_flatten()

rules <- expand_grid(
  matching = c("stems", "exact"),
  categories = subsets,
  k = 1:3
) |>
  mutate(
    coded = pmap(list(matching, categories, k), \(matching, categories, k) {
      rowSums(counts[[matching]][categories]) >= k
    }),
    agreements = map_int(coded, \(x) sum(x & stories$ach)),
    coder = map_int(coded, sum),
    reference = sum(stories$ach),
    precision = agreements / coder,
    recall = agreements / reference,
    category_agreement = 2 * agreements / (coder + reference),
    n_categories = lengths(categories),
    categories = map_chr(categories, str_flatten, "+")
  ) |>
  select(-coded) |>
  arrange(desc(category_agreement), n_categories, k, desc(matching))

rules

# Any word of any of the six categories, for comparison.
rules |>
  filter(matching == "stems", n_categories == 6, k == 1)

# The rule kept ----------------------------------------------------------------

# Written once, before any reserved sentence is coded, and not changed after.
rule_file <- file.path(runs_dir, "dictionary_rule.json")
if (!file.exists(rule_file)) {
  rules |>
    slice(1) |>
    transmute(
      motive = "ACH",
      categories = str_split(categories, fixed("+")),
      stem = matching == "stems",
      k
    ) |>
    as.list() |>
    jsonlite::write_json(rule_file, auto_unbox = TRUE, pretty = TRUE)
}
jsonlite::read_json(rule_file, simplifyVector = TRUE)[c(
  "categories",
  "stem",
  "k"
)]
