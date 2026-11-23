# Revision Log: Motive-Imagery Coding Specification

One entry per version: what changed, why, and the cases that prompted it. Cases are named by story and sentence (`PC24.3` is the third sentence of story `PC24`; `CB17` is sentence 17 of the speech). Versions up to v0.3 were informed only by practice sets `PA` to `PF`. Version 0.4 was informed by the two calibration sets and the first email test, after they had served once as reserved material under the frozen v0.3 and KB had said to read their disagreements (22 November 2026). No case of the email hold-out has informed any version.

A change made in the light of a case removes that case as evidence. Agreement on the practice stories after a revision shows that the revision did what it was meant to do on the cases that prompted it, and nothing more.

Page references are to Winter (1994), *Manual for Scoring Motive Imagery in Running Text*, Version 4.2, read from the scan's OCR text. They have not been rechecked against the page images.

---

## v0.2 (20 November 2026)

The starting point of the pilot, decided as 04-D02. The model lists every image and the manual's counting rule is applied afterwards in code. Its header records what changed from v0.1.

## v0.3 (21 November 2026) — frozen by KB on 22 November 2026

Frozen for the reserved run. The file's header was changed to say so, which changes the hash of the file and not of the instructions: instructions SHA-256 `2316743c2316e3e7` before and after; file `4931f27d65239f5f` as piloted, `ec0c6de0151b0860` as frozen. A further change of any kind is a new version in a new file.

Revised by an AI assistant after the first pilot run, at KB's instruction to run the worked example. The first run coded the 180 practice stories under v0.2 with the main configuration. Its disagreements with the practice-set labels were read in both directions, and each pattern below was then checked against the manual's own wording. Every change restores a rule of the manual that v0.2's condensation had narrowed or widened. No change was made only because the labels disagreed.

The schema, the input format, the counting rule, and the agreement index are unchanged.

| # | Change | Reason | Manual | Cases that prompted it |
|:--|:--|:--|:--|:--|
| 1 | General rule 6 added: apply only the rules given, and draw on nothing recalled about the text or about how it has been scored elsewhere | KB's suggested precaution against the model reproducing a published scoring (brief, choice 3). It is a precaution and not evidence that no such knowledge is used | — | None |
| 2 | `ACH1` widened from a performance "judged good, better, or best" to any word of positive evaluation applied to a performance, its result or product, or a person's work or ability, including where the performance is implicit | v0.2 dropped the manual's "outcomes of implicit performances". The model missed evaluative words attached to things and people | p. 8 | Missed: `PF10.1`, `PD26.1`, `PF11.3`, `PF15.6`, `PE7.6`, `PF30.3`, `PF30.6`, `PA25.1`, `PA29.9` |
| 3 | `ACH2` tightened: care, concentration, effort, practice, or checking counts only where the sentence connects it to a good result | The manual calls effort without that connection "task imagery" and does not score it. v0.2 said so only in its closing list, and the model listed these freely | pp. 8–9 | Added: `PD25.4`, `PE24.2`, `PE19.1`, `PD16.2`, `PD24.1`, `PF1.5`, `PF7.4` |
| 4 | `ACH4` tightened: the sentence must itself state sadness, another negative feeling, or concern to do better | The manual does not score failure reported without feeling. The model listed bare difficulty and lack of progress | p. 10; review example, p. 11 | Added: `PC24.3`, `PC24.4`, `PC24.5`, `PB22.4`, `PA23.3`, `PA22.7`, `PF20.11` |
| 5 | `ACH5` restated as something an actor does or aims to do; a thing or event that is merely rare, new, or mysterious is excluded; working on an unsolved problem is included | The manual's criterion is an "action or goal". The model listed rare objects and unusual events, and missed work towards a cure | p. 10 | Added: `PC1.1`, `PF14.1`, `PD27.3`, `PD7.4`, `PC29.1`. Missed: `PD18.1`, `PC26.5` |
| 6 | "Important, crucial, or serious" added to what is not achievement; the old exclusion of failure without feeling moved into `ACH4` | Importance of a task is not a standard of excellence in the manual. The model listed it under `ACH1` | pp. 8–10 | Added: `PA25.7`, `PB21.3`, `PB27.4`, `PC27.2` |
| 7 | `AFF1` widened: the words for friendship and marriage are listed unless the warmth is denied; wanting to be with family or friends counts | The manual says these terms are almost always scored. v0.2's "warmth must be expressed" led the model to pass over them | p. 12 | Missed: `PB3.1`, `PB3.3`, `PC7.1`, `PF4.3`, `PD8.2`, `PD8.4`, `PD6.5` |
| 8 | `AFF3` widened: people who have a relationship spending time, walking, or talking with no practical purpose | The manual scores shared time and "noninstrumental talk" between people with a relationship | p. 13 | Missed: `PB12.2`, `PB14.1`, `PC13.5`, `PD30.1`, `PE26.1` |
| 9 | `POW6` restated: any strong reaction, positive or negative, to another's intentional act; the effect need not be intended | v0.2's "where the effect runs one way" discouraged its use: the model applied `POW6` twice in 506 images, and missed anger and disappointment at another's act | p. 18 | Missed: `PB10.3`, `PB2.3`, `PF18.3`, `PC4.2` |
| 10 | `review_needed` restricted to sentences with two readings that the rules do not settle | The model flagged 349 of 1,142 sentences, which makes the flag useless for directing human review | — | The whole run |

### What the Revision Did on the Practice Stories

Main configuration, one run under each version, with a second run under v0.3 to show how much the output varies when nothing is changed. The index is the manual's category agreement after the counting rule, with the same motive in adjacent sentences counted as an agreement (manual, p. 31). The manual's standard is .85.

| | v0.2 | v0.3 | v0.3, repeated |
|:--|--:|--:|--:|
| Achievement | .74 | .80 | .79 |
| Affiliation-intimacy | .72 | .78 | .80 |
| Power | .71 | .74 | .75 |
| Sentences flagged for review | 349 | 89 | 93 |

The two v0.3 runs agree with each other on which sentences carry achievement imagery at .93 on the same index (.97 for affiliation, .94 for power). The v0.2 and v0.3 runs agree at .79, so the revision changed the output by more than repetition does.

The second coder, `deepseek-flash`, under v0.3 with all 180 stories coded: achievement .74, affiliation-intimacy .76, power .77. It lists more images than the main configuration (612 against 528) and flags two sentences for review. The two coders agree with each other on which sentences carry achievement imagery at .80 (.87 for affiliation, .79 for power). Its v0.2 run is not comparable, because 18 stories failed at the output cap (`LOG.md`).

A third coder, `deepseek-v4-pro`, was piloted on 22 November under the frozen v0.3, at KB's request, as a candidate for the second configuration: achievement .76, affiliation-intimacy .76, power .76, with 566 images listed and no sentence flagged for review. It agrees with the main configuration on which sentences carry achievement imagery at .82 (.85 for affiliation, .79 for power), and with `deepseek-flash` at .80 (.88, .81). On achievement the two DeepSeek models differ from each other about as much as each differs from the main configuration, and the gap between them on the labels (.76 against .74) is within what one repetition of the main configuration moves (.80 against .79). KB chose `deepseek-flash` as the declared second coder on 22 November.

These figures are development evidence. The specification was revised in the light of these stories, and the labels they are compared with do not follow the consecutive-sentence rule in every story (`LOG.md`, 21 November, design-stage figures).

### What Remains, and Why It Was Left

Read after the v0.3 run, for achievement (33 sentences added, 10 missed, of which 14 differ from the labels only in which of two adjacent sentences carries the image):

- **The model lists more than the labels do.** Most remaining additions are sentences that a reader applying the manual could defend: a result called effective or encouraging, an experiment completed satisfactorily, people who work well together. Whether the expert passed over them, or scored a neighbouring sentence instead, cannot be told from the labels. An instruction that removed them would be fitted to the labels and not to the manual. Left alone.
- **`ACH4` is still sometimes applied to failure without stated feeling** (`PA22.7`, `PB22.4`, `PA23.3`), although the instruction now excludes it. A further tightening risks losing the cases where feeling is implied by the context. Left as it is at the freeze.
- **A question that expresses concern about failure** (`PB27.6`) is scored in the labels and excluded by general rule 3. One case. Left alone.
- **Power is the weakest motive**, and its remaining misses are varied: acts whose force lies in the story's situation more than in the sentence. No single instruction would cover them.

By the brief's stopping rule the remaining errors are unsystematic, or systematic and not fixable by instruction without fitting the labels. KB stopped at v0.3 and froze it on 22 November 2026.

## v0.4 (22 November 2026) — draft, not frozen

Drafted by an AI assistant at KB's instruction, after the reserved run under v0.3 fell short of the manual's standard on both calibration sets and the disagreements were read (`LOG.md`, step 8). Each pattern in the disagreements was taken to the manual's wording before anything was changed. Every change restores or spells out a rule the manual states. No change was made only because a reference disagreed, and the patterns the manual does not settle were left alone (below).

The schema, the input format, the counting rule, and the agreement index are unchanged. The instructions' SHA-256 begins `908ac155f32b5225`.

| # | Change | Reason | Manual | Cases that prompted it |
|:--|:--|:--|:--|:--|
| 1 | The actor of an image may be an impersonal thing or abstraction treated as acting, and the act may be in the passive with the actor unnamed | The manual's definition of an image admits a personified impersonal entity or abstraction, its definition of power any "person-like entity", and its examples score what a policy does. v0.3 named only people, groups, institutions, and nations, and the model passed over power exercised by a government, a policy, or an unnamed agent. That the act may be in the passive is the reviser's reading: nothing in the manual requires the actor to be named | pp. 4, 15, 20 | Missed: `CA2.7`, `CA4.7`, `CA23.2`, `CB34`, `CB48`, `CB52`, `CB98` |
| 2 | `ACH1`: one word of excellence standing alone is enough, and it may be applied to a thing that is the outcome of a performance only implied (a plan, a place, a country, a future) | The manual scores the adjective itself, and scores "great" used by itself of a country. Revision 2 of v0.3 had widened `ACH1` to products and abilities and no further | pp. 8, 19 | Missed: `CA5.7`, `CA8.6`, `CA27.6`, `CB17`, `CB33`, `CB40`, `CB54`, `CB70`, `CB79` |
| 3 | `ACH2`: progress, growth, improvement, advance, or moving forward is listed wherever it is sought or valued; "rehearsal" added to effort that does not count | The manual says progress and economic growth as goals can be assumed to involve excellence, and its review examples score "moving forward" | pp. 9, 11 | Missed: `CA16.2`, `CB51`, `CB58`, `CB73`, `CB106`, `CB111`, `CB112`. Added: `CA25.4` |
| 4 | `ACH5`: the newness must suggest excellence; an actor's own first attempt or difficult move does not | The manual's criterion ends "thereby suggesting an implicit standard of excellence". That a first for the actor does not meet it is the reviser's reading of that clause, not a sentence of the manual | p. 10 | Added: `CA17.7`, `CA22.4`, `CA25.7` |
| 5 | Affiliation: in public or formal text the fainter signs are listed. A people or group united, as one, standing together, or joined in a common cause; "friends" in address | The manual scores unity of a people and asks the scorer to be alert to subtler cues in political material. v0.3's exclusion of "routine forms of address" and of "working together with no warmth" was wider than the manual's, which excludes ideological formulas and a routine arrangement to work with someone | pp. 12–14 | Missed: `CB13`, `CB44`, `CB56`, `CB113`, `CB124` |
| 6 | Not affiliation: a relative, a home, a meal, a meeting, or a touch mentioned with no friendly feeling or enjoyment of the company stated | The manual: connection, association, or common activity is not enough without a warm quality. v0.3 said so in general terms and the model listed these all the same. The list is the reviser's elaboration | p. 12 | Added: `CA1.7`, `CA7.7`, `CA8.7`, `CA24.4`, `CA28.2`, `CA30.4` |
| 7 | `POW2`: control includes limiting or restraining what people, groups, or institutions do | The manual's criterion is "control or regulation", of which gathering information is the leading case and not the only one | p. 16 | Missed: `CB66`, `CB80` |
| 8 | `POW4`: unrequested help needs nothing more said about its effect; protecting, caring for, consoling, and encouraging are named. The boundary rule now says to list `AFF4` beside `POW4` where there is warmth, and not in its place | v0.3's boundary rule read "POW (unrequested, with impact)". The manual asks for impact only when help was requested. Its own examples of `POW4` include consoling and encouraging, and it says helping acts scored for affiliation are often scored for power as well | pp. 14, 16–17, 20 | Missed: `CA18.5`, `CA19.4`, `CB54`, `CB73`; offers of help labelled power in the first email test |
| 9 | `POW6`: the feeling runs one way; setting out to produce it counts; a one-sided feeling is affiliation only where friendly or loving feeling toward the other is stated or the feeling is mutual | The manual's examples include being enchanted by an evening someone arranged and leaders who will stir hope, and it separates transitive from mutual effects. The model listed one-sided delight and enchantment as warm feeling | p. 18 | Missed: `CA9.1`, `CA15.2`, `CA29.3` |
| 10 | Not power: a role or trait named with no act; an ordinary request or instruction in the course of work | The manual does not score routine orders, or a word for a role where no leading or impact is involved | pp. 15–16 | Added: `CA16.4`; routine requests in the sample of email additions |
| 11 | Boundary: changing, conquering, destroying, saving, or leading the world or a large part of it is `POW1`, and `ACH5` as well only where it is presented as a discovery, an invention, or a first | The manual's definition of power includes impact on the world at large, and it separates doing something excellently from having impact. The model listed these as unique accomplishments | pp. 15, 19 | Missed: `CB40`, `CB96`, `CB108` |

Eight constructed sentences were added to the eight of v0.3, one for each new rule that can be shown in a sentence. Both coders return the proposed motives on all sixteen. Two criteria differ within a motive: `ACH1` for `ACH2` on the eighth, and `POW2` for `POW1` on the sixteenth.

### What the Revision Did on the Development Material

Main coder, one run under each version. The second coder's figures follow the main coder's tables.

On the practice stories the index is as before: category agreement after the counting rule against Pang and Ring's labels, adjacent sentence allowed. These stories prompted v0.3 and did not prompt v0.4.

| Practice stories | v0.3 | v0.3, repeated | v0.4 |
|:--|--:|--:|--:|
| Achievement | .80 | .79 | .77 |
| Affiliation-intimacy | .78 | .80 | .77 |
| Power | .74 | .75 | .76 |

On the calibration sets the index is category agreement with the transcribed key, in the key's sentences, and then with the adjacent sentence allowed. These sets prompted v0.4.

| Calibration Set A | v0.3 | v0.4 |
|:--|--:|--:|
| Achievement | .63 / .78 | .83 / .88 |
| Affiliation-intimacy | .67 / .74 | .83 / .83 |
| Power | .71 / .71 | .86 / .86 |

| Calibration Set B | v0.3 | v0.4 |
|:--|--:|--:|
| Achievement | .57 / .61 | .80 / .80 |
| Affiliation-intimacy | .73 / .73 | .82 / .82 |
| Power | .39 / .39 | .75 / .79 |

Second coder, `deepseek-flash`, one run under each version, no failed request (652 images listed on the practice stories, 135 on Set A, 110 on Set B):

| Second coder | v0.3 | v0.4 |
|:--|--:|--:|
| Practice stories, achievement | .74 | .74 |
| Practice stories, affiliation-intimacy | .76 | .76 |
| Practice stories, power | .77 | .76 |
| Calibration Set A, achievement | .55 / .77 | .65 / .83 |
| Calibration Set A, affiliation-intimacy | .65 / .77 | .67 / .74 |
| Calibration Set A, power | .77 / .89 | .82 / .85 |
| Calibration Set B, achievement | .57 / .68 | .71 / .81 |
| Calibration Set B, affiliation-intimacy | .68 / .73 | .79 / .79 |
| Calibration Set B, power | .61 / .70 | .68 / .83 |

The second coder gains less than the main coder on the stories and about as much on the speech. On Set A it still lists far more affiliation than the expert (36 images against 21), so the tightened affiliation rules took less hold on it.

The revision did what it was meant to do on the cases that prompted it, and that is all the calibration figures show. Where the cases did not prompt it, on the practice stories, nothing moved by more than a repetition moves it. The gain on the calibration sets is therefore no estimate of what v0.4 would do on new material. On the speech the main coder now lists 83 images where it listed 45.

### What Remains, and Why It Was Left

- **Stock courtesies in letters and email** ("hope you are well", "look forward to seeing you"). The manual's rule for welcomes is that a formal one is not scored and an elaborated one is. It says nothing of the conventions of a letter. Pang and Ring's coders marked some and not others, and so does the model. Left for an author to decide.
- **"Wanting to be with family or friends counts"** (revision 7 of v0.3) was prompted by practice cases and conflicts with one calibration case (`CA30.6`). Left as it is.
- **Words of pleasure and beauty.** The expert does not score "beautiful" or "pretty" as achievement and does score "superb". The manual gives no rule. `ACH1` now says the word must say how good the thing is and not that it is pleasant, which is the reviser's gloss on "standard of excellence".
- **Cases the manual does not settle:** the star of a show scored for achievement where both coders list prestige (`CA21.1`); a reassurance not scored as a nurturant act (`CA9.6`); a wish to talk away from work not scored as companionate (`CA11.4`).
- **The counting rule compounds an error** in the sentence before (`CA19.7`, `CA25.5`, `CA28.3`). Nothing in the instructions can remove this.

### Where This Leaves the Test

The calibration sets and practice sets `PA` to `PF` are now development material. The email hold-out is untouched, and its labels cannot measure precision (`LOG.md`, step 8). Corrected later on 22 November: this entry first said that every text the manual's expert scored was spent. The manual's practice Sets G to M also carry expert scoring, are not in Pang and Ring's files, and have not been opened in this work (`LOG.md`, step 11). They would have to be transcribed before they could serve as a test.

## v0.5 (22 November 2026) — draft, not frozen

Version 0.4 with one rule added. KB decided on 22 November that the stock courtesies of email are not scored (`notes/decisions/04-decisions.qmd`). It is a version of its own so that the runs made under v0.4 still correspond to the text they used. Written by an AI assistant at KB's instruction. Instructions SHA-256 `724b3ae6b965b035`.

| # | Change | Reason | Manual | Cases that prompted it |
|:--|:--|:--|:--|:--|
| 12 | Not affiliation: the stock courtesies of a letter or message (a greeting, a sign-off, hoping the reader is well, good wishes for a weekend or a holiday, looking forward to seeing or hearing from the reader), unless the sentence goes on to say something warm about the relationship itself | An author's decision. The manual has no rule for the conventions of a letter. The rule follows the pattern of its rule for welcomes, which are not scored when only formal and are scored when elaborated in an affiliative way | pp. 13–14, by analogy | In the first email test: 26 sentences hoping the reader is well, of which Pang and Ring's labels mark 9 and the main coder under v0.3 marked 7; 29 looking forward to seeing, meeting, or hearing, labels 6, coder 10 |

Two constructed sentences were added, a bare courtesy and a courtesy that goes on to say something warm. Both coders return the proposed motives on all eighteen.

### What the Rule Did

The 68 first-test emails that contain a stock courtesy (387 sentences) were coded under v0.5 by the main coder. Sentences marked for affiliation:

| | Sentences | Labels | v0.3 | v0.5 |
|:--|--:|--:|--:|--:|
| Hoping the reader is well | 26 | 9 | 7 | 1 |
| Looking forward to seeing, meeting, or hearing | 29 | 6 | 10 | 0 |
| Good wishes for a weekend or holiday | 13 | 0 | 0 | 0 |
| The other sentences of the same emails | 319 | 9 | 33 | 22 |

The rule does what it says. The labels and v0.5 now differ on these sentences by design: Pang and Ring's coders scored 15 of them and v0.5 scores one.

On the stories and the speech, v0.5 differs from v0.4 by one sentence that hardly applies to them, so the two runs are close to a repetition. Main coder, category agreement as in the tables above:

| | v0.3 | v0.4 | v0.5 |
|:--|--:|--:|--:|
| Practice stories, achievement | .80 | .77 | .81 |
| Practice stories, affiliation-intimacy | .78 | .77 | .77 |
| Practice stories, power | .74 | .76 | .76 |
| Calibration Set A, achievement | .63 / .78 | .83 / .88 | .80 / .89 |
| Calibration Set A, affiliation-intimacy | .67 / .74 | .83 / .83 | .79 / .83 |
| Calibration Set A, power | .71 / .71 | .86 / .86 | .86 / .86 |
| Calibration Set B, achievement | .57 / .61 | .80 / .80 | .76 / .79 |
| Calibration Set B, affiliation-intimacy | .73 / .73 | .82 / .82 | .79 / .79 |
| Calibration Set B, power | .39 / .39 | .75 / .79 | .74 / .78 |

The differences between v0.4 and v0.5 on the calibration sets, up to four points, are a measure of how much one run varies and not an effect of the rule. Both drafts reach the manual's .85 on Set A for power and, with the adjacent sentence allowed, for achievement. They fall short of it on Set A for affiliation and on Set B for all three motives, and both leave the practice stories where v0.3 had them.

## v0.6 (22 November 2026) — draft, not frozen

A second round of refinement, at KB's instruction, from what Sonnet 5.5 and Opus 5.5 still differed on from the expert in the two calibration sets under v0.5 (81 of 344 sentences). Each pattern was taken to the manual's wording. Written by an AI assistant. Instructions SHA-256 `444332c7bba398c4`.

| # | Change | Reason | Manual | Cases that prompted it |
|:--|:--|:--|:--|:--|
| 13 | A long sentence is taken clause by clause and each image listed; the same motive is listed again in a sentence where another motive comes between; a phrase joining two concerns gives two images | The manual scores two images of one motive in a sentence when another motive separates them, and its own example splits doing one's best from the glory that follows. In dense sentences the coders listed one image for a phrase the expert scores twice | pp. 19, 21 | Missed: `CA23.1`, `CB11`, `CB15`, `CB57`, `CB85`, `CB108`, `CB126` |
| 14 | `ACH4`: a resolve not to repeat past errors is concern to do better | The criterion includes "concern to do better" | p. 10 | Missed: `CB47` |
| 15 | `AFF3`: peace among people or nations counts where it is sought, worked for, prayed for, or preserved | The manual scores peace mentioned with emotional commitment or as preserving good relations, and scores working for peace. v0.3 kept only peace "bringing people together" | p. 13 | Missed: `CB35`, `CB82`, `CB108` |
| 16 | `AFF4`: compassion or care for others named as a value or an aim | The manual's review examples score a government that must be compassionate | p. 14 | Missed: `CB71` |
| 17 | `POW5`: concern with how one will be judged or remembered, by others or by history | The criterion is mention of, or concern about, fame, prestige, or reputation | p. 17 | Missed: `CB38` |
| 18 | Boundary: help to the sick, the hungry, the poor, the old, or the weak is both `POW4` and `AFF4`; help or encouragement that people give one another is `AFF4` alone | The manual's review examples score safeguarding people's health as a nurturant act, and it says such acts are often power as well; helping as co-acting is affiliation and not necessarily power. Under v0.5 the coders listed `POW4` and dropped `AFF4` | pp. 14, 16–17 | Missed: `CB54`, `CB120` |
| 19 | Boundary: leading in a field, a race, or an advance, in the sense of being ahead, is `ACH3` and not power | Change 11 of v0.4 sent all "leading" to power. The manual scores being ahead of other nations in growth as achievement | p. 9 | Wrong motive: `CB57` |

Five constructed sentences were added. Sonnet and Opus return the proposed motives on all twenty-three.

### What the Round Did

Category agreement by the manual's rule for an agreement (the same or the adjacent sentence); achievement, affiliation-intimacy, power, and then all three together.

| | v0.3 | v0.5 | v0.6 |
|:--|--:|--:|--:|
| Set A, Sonnet 5.5 | .78, .74, .71 (.74) | .89, .83, .86 (.86) | .89, .82, .85 (.85) |
| Set A, Opus 5.5 | .76, .82, .80 (.79) | .83, .88, .92 (.88) | .84, .84, .84 (.84) |
| Set B, Sonnet 5.5 | .61, .73, .39 (.59) | .79, .79, .78 (.79) | .81, .85, .72 (.80) |
| Set B, Opus 5.5 | .70, .63, .55 (.63) | .71, .76, .80 (.76) | .79, .85, .77 (.80) |
| Practice stories, Sonnet 5.5 | .80, .78, .74 (.77) | .81, .77, .76 (.78) | .82, .76, .78 (.78) |
| Practice stories, Opus 5.5 | .79, .80, .78 (.79) | .80, .79, .79 (.79) | .80, .76, .80 (.79) |

The round did what it aimed at in the speech: affiliation there rises to .85 for both coders. It did not carry the speech as a whole to the standard, and it cost a point or two on the stories, where both coders now list more affiliation and power than under v0.5. Against a run-to-run variation of up to four points, v0.6 is not clearly better than v0.5. The instructions have stopped yielding gains of the size the first round gave.

### What Remains, and Why It Was Left

- **An elaborated welcome** (`CB2`), which the expert scores and both coders pass over. A rule for it would sit against KB's decision that stock courtesies are not scored. Left.
- **Wanting a relative to stay, come home, or visit** (`CA30.2`, `CA30.6`, `CA30.7`), which both coders list under revision 7 of v0.3 and the expert does not score. The practice cases and this story point opposite ways. Left.
- **"Going forward" and progress on the way to a goal** (`CB64`, `CB77`), listed under change 3 of v0.4 where the expert scores some uses and not others. Left.
- **Single cases with no rule to state:** knowledge credited to two people (`CA18.2`), the star of a show (`CA21.1`), a result that "worked" (`CA19.6`), demands of an institution (`CB48`).

## v0.6 with worked examples (22 November 2026) — a new version of the specification, with the instructions unchanged

KB decided on 22 November to add expert-scored practice stories to the request. The instructions of v0.6 are unchanged. The examples are part of what the coder is given, so this is a new version of the coding specification (Chapter 4, section 4.4), although it has no file of its own: the examples are appended when `12_worked_examples.R` runs and are not in this folder, because the stories are in copyright. Each sentence of an example story is followed by the motives the expert scored in it, as Pang and Ring transcribed them.

Category agreement by the manual's rule, all three motives together:

| | v0.6 | With sets A to C (90 stories) | With sets A to F (180 stories) |
|:--|--:|--:|--:|
| Calibration stories, Sonnet 5.5 | .85 | .85 | .83 |
| Calibration stories, Opus 5.5 | .84 | .88 | .86 |
| Calibration speech, Sonnet 5.5 | .80 | .85 | .83 |
| Calibration speech, Opus 5.5 | .80 | .84 | .82 |

With 90 examples Opus is at .85 or better on each motive in the calibration stories. `LOG.md`, step 14, has the figures by motive and their limits.

