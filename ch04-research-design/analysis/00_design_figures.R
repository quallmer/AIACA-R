# Design-stage figures for the worked example.
#
# Four descriptions of the development stories, computed from the expert's
# labels and a dictionary before any model is run:
#   A1  how rare the imagery is and how it clusters
#   A2  how different aggregation rules order the same stories
#   A3  what the six General Inquirer categories match and miss
#   A4  how many images a 30-story test is likely to hold
# For the reserved material only stories, sentences, and words are counted.

source("R/setup.R")

count_words <- function(text) {
  quanteda::ntoken(quanteda::tokens(
    text,
    remove_punct = TRUE,
    remove_symbols = TRUE
  ))
}
stories <- read_stories(labels = TRUE) |>
  mutate(words = count_words(text))
development <- stories |>
  filter(role == "development")

# The material -----------------------------------------------------------------

stories |>
  summarise(
    stories = n_distinct(doc),
    sentences = n(),
    words = sum(words),
    .by = c(set, role)
  )

# each story's rows are together in the file
stopifnot(identical(rle(stories$doc)$values, unique(stories$doc)))

# A1. Reference audit ----------------------------------------------------------

development |>
  summarise(stories = n_distinct(doc), sentences = n(), words = sum(words))

development |>
  pivot_longer(all_of(motives), names_to = "motive", values_to = "present") |>
  summarise(
    positive_sentences = sum(present),
    share_of_sentences = mean(present),
    per_1000_words = 1000 * sum(present) / sum(words),
    share_of_stories = n_distinct(doc[present]) / n_distinct(doc),
    .by = motive
  )

# Achievement by practice set. The manual calls sets A to C more selected and
# D to F more typical.
development |>
  summarise(
    sentences = n(),
    positive = sum(ach),
    share = mean(ach),
    stories_with_any = n_distinct(doc[ach]),
    .by = set
  )

# Clustering within stories.
per_story <- development |>
  summarise(
    sentences = n(),
    words = sum(words),
    count = sum(ach),
    # consecutive positive sentences scored once, a third again
    count_manual = with(rle(ach), sum(ceiling(lengths[values] / 2))),
    .by = doc
  )
per_story |>
  count(count) |>
  mutate(share_of_positives = n * count / sum(n * count))

# Adjacent pairs of positive sentences, and those in which neither sentence
# carries another motive, so that the manual would score the pair once.
development |>
  mutate(
    follows = ach & lag(ach, default = FALSE),
    alone = !(aff | pow) & !lag(aff | pow, default = FALSE),
    .by = doc
  ) |>
  summarise(
    adjacent_pairs = sum(follows),
    no_other_motive = sum(follows & alone),
    share_of_positives = sum(follows) / sum(ach)
  )

# A2. Aggregation --------------------------------------------------------------

scores <- per_story |>
  mutate(
    per_1000_words = 1000 * count / words,
    prop_sentences = count / sentences
  )

scores |>
  summarise(
    stories = n(),
    with_imagery = sum(count > 0),
    median_words = median(words),
    median_words_with = median(words[count > 0]),
    median_words_without = median(words[count == 0])
  )

spearman <- function(d) {
  d |>
    select(count, per_1000_words, prop_sentences, words) |>
    cor(method = "spearman") |>
    round(2)
}
spearman(scores)
spearman(filter(scores, count > 0))

# Pairs of stories with imagery that two rules order in opposite ways.
with_imagery <- filter(scores, count > 0)
pairs <- combn(nrow(with_imagery), 2)
ordering <- function(x) sign(x[pairs[1, ]] - x[pairs[2, ]])
mean(ordering(with_imagery$count) * ordering(with_imagery$per_1000_words) < 0)
mean(
  ordering(with_imagery$per_1000_words) *
    ordering(with_imagery$prop_sentences) <
    0
)

# Sentence-by-sentence presence against the manual's consecutive-sentence rule.
scores |>
  summarise(
    presence = sum(count),
    manual_rule = sum(count_manual),
    stories_changed = sum(count != count_manual)
  )

# A3. Dictionary coverage ------------------------------------------------------

coverage <- function(stem) {
  matched <- category_counts(development$text, stem = stem) > 0
  positive <- development$ach
  list(
    overall = tibble(
      positives_with_no_match = sum(positive & rowSums(matched) == 0),
      negatives_with_a_match = sum(!positive & rowSums(matched) > 0),
      share_positive_among_matched = mean(positive[rowSums(matched) > 0])
    ),
    by_category = tibble(
      category = inquirer_categories,
      entries = lengths(read_inquirer()),
      share_of_positives_matched = colMeans(matched[positive, ]),
      share_of_negatives_matched = colMeans(matched[!positive, ])
    )
  )
}
coverage(stem = TRUE)
coverage(stem = FALSE)

# A4. Planning the reserved test -----------------------------------------------

# Each practice set has 30 stories, as Calibration Set A has.
development |>
  summarise(across(all_of(motives), sum), .by = set)

# The manual's index is twice the agreements over the scorer's images plus the
# expert's. With n expert images and e errors, half misses and half additions:
agreement <- function(n, missed, added) {
  2 * (n - missed) / (2 * n - missed + added)
}
expand_grid(n = c(12, 14, 18), errors = 0:36) |>
  mutate(index = agreement(n, ceiling(errors / 2), floor(errors / 2))) |>
  summarise(
    one_missed = agreement(first(n), 1, 0),
    errors_allowed = max(errors[index >= 0.85]),
    .by = n
  )

# The emails, structure only.
read_excel(file.path(data_dir, "UD2_sentences.xlsx")) |>
  summarise(sentences = n(), emails = n_distinct(Filename), .by = Person) |>
  summarise(
    writers = n(),
    emails = sum(emails),
    fewest_sentences = min(sentences),
    most_sentences = max(sentences),
    sentences = sum(sentences)
  )
