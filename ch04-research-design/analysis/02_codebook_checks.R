# Step 2. Checks on the specification before it meets any source material.

source("R/setup.R")

# The counting rule and the agreement index, on cases worked by hand -----------

# Which of the listed images are scored (manual, p. 21)?
scored <- function(sentence, motive, doc = "d") {
  tibble(doc, sentence, motive) |>
    mutate(order = row_number(), .by = c(doc, sentence)) |>
    apply_counting_convention() |>
    pull(scored)
}

stopifnot(
  "one sentence, one motive listed twice: scored once" = identical(
    scored(c(1, 1), c("ACH", "ACH")),
    c(TRUE, FALSE)
  ),
  "one sentence, two motives: each scored" = identical(
    scored(c(1, 1), c("ACH", "POW")),
    c(TRUE, TRUE)
  ),
  "two consecutive sentences, same motive: scored once" = identical(
    scored(c(1, 2), c("ACH", "ACH")),
    c(TRUE, FALSE)
  ),
  "three consecutive sentences, same motive: first and third" = identical(
    scored(1:3, rep("ACH", 3)),
    c(TRUE, FALSE, TRUE)
  ),
  "four consecutive sentences, same motive: first and third" = identical(
    scored(1:4, rep("ACH", 4)),
    c(TRUE, FALSE, TRUE, FALSE)
  ),
  "sentences 1 and 3, same motive: both scored" = identical(
    scored(c(1, 3), c("ACH", "ACH")),
    c(TRUE, TRUE)
  ),
  "consecutive sentences with another motive between: both scored" = identical(
    scored(c(1, 1, 2), c("ACH", "POW", "ACH")),
    c(TRUE, TRUE, TRUE)
  ),
  "same sentence, ACH POW ACH: all three scored" = identical(
    scored(c(1, 1, 1), c("ACH", "POW", "ACH")),
    c(TRUE, TRUE, TRUE)
  ),
  "another motive after the second image does not rescue it" = identical(
    scored(c(1, 2, 2), c("ACH", "ACH", "POW")),
    c(TRUE, FALSE, TRUE)
  ),
  "documents are counted separately" = identical(
    scored(c(1, 1), c("ACH", "ACH"), doc = c("a", "b")),
    c(TRUE, TRUE)
  )
)

# The agreement index (manual, pp. 30-31): twice the agreements over the two
# scorers' totals, with and without the adjacent sentence allowed.
scorer <- tibble(doc = "d", sentence = c(1, 4, 7), motive = "ACH")
expert <- tibble(doc = "d", sentence = c(2, 4, 9), motive = "ACH")

stopifnot(
  "same sentence required: one agreement of three and three" = all.equal(
    category_agreement(scorer, expert, tolerance = 0)[
      "ACH",
      "category_agreement"
    ],
    1 / 3
  ),
  "adjacent sentence allowed: two agreements of three and three" = all.equal(
    category_agreement(scorer, expert, tolerance = 1)[
      "ACH",
      "category_agreement"
    ],
    2 / 3
  )
)

# Constructed sentences, through each model ------------------------------------

# Written for the purpose and not taken from the manual. They show whether the
# request, the output format, and the plainest rules work. They are not
# evidence of performance.
checks <- constructed_checks |>
  as_tibble() |>
  transmute(doc = str_c("K", row_number()), text = sentence, proposed)

checked_main <- qlm_code(
  document_inputs(checks),
  motive_codebook,
  model = models[["main"]],
  params = params(max_tokens = max_tokens),
  name = "main"
)
checked_second <- qlm_replicate(
  checked_main,
  model = models[["second"]],
  name = "second"
)

returned <- function(coded) {
  image_list(coded) |>
    summarise(returned = str_flatten(criterion, " then "), .by = doc)
}

checks |>
  left_join(returned(checked_main), by = "doc") |>
  left_join(
    returned(checked_second),
    by = "doc",
    suffix = c("_main", "_second")
  ) |>
  mutate(across(starts_with("returned"), \(x) coalesce(x, "none"))) |>
  select(-text)
