TimeUtils
---------

`TimeUtils` is a small library that mimics a part of the Rails
utilities for working with dates and date-times.  Some examples are
shown here.

  iex> import TimeUtils
  nil

  iex> now
  {{2013, 9, 3}, {17, 31, 19}}

  iex> tomorrow
  {{2013, 9, 4}, {17, 32, 5}}

  iex> 10 |> minutes |> ago
  {{2013, 9, 3}, {17, 26, 36}}

  iex> 15 |> hours |> from_now
  {{2013, 9, 4}, {8, 38, 6}}

It handles the number of days according to the involved months.

  iex> 28 |> days |> from_now
  {{2013, 10, 1}, {17, 40, 21}}

  iex> 3 |> days |> ago
  {{2013, 8, 31}, {17, 42, 44}}

We can give a reference date or time for calculations.

  iex> 2 |> months |> from 3 |> days |> ago
  {{2013, 10, 31}, {17, 47, 40}}

  iex> 4 |> months |> before 2 |> weeks |> from_now
  {{2013, 5, 17}, {17, 48, 54}}

However, since it does eager checking, calculations resulting in
February are *not* commutative if the year is a leap year.  Please
bear that in mind.

  iex> 6 |> months |> before 3 |> years |> from 3 |> days |> ago
  {{2016, 2, 29}, {17, 45, 33}}

  iex> 3 |> years |> from 6 |> months |> before 3 |> days |> ago
  {{2016, 2, 28}, {17, 46, 3}}

In general, you should apply the month transformation(s) as the last,
for more accurate results.

Explicit parentheses could help increase readability in cases such as
above.  We are more likely to have variables in real code, of course,
making it look much less ambiguous.

  iex> q = 3
  3
  iex> a_date = q |> days |> ago
  {{2013, 8, 31}, {18, 6, 12}}
  iex> a_date = q |> years |> from a_date
  {{2016, 8, 31}, {18, 6, 12}}
  iex> p = 6
  6
  iex> p |> months |> before a_date
  {{2016, 2, 29}, {18, 6, 12}}

Implementation Notes
--------------------

All numeric parameters for calculation are converted into one of
seconds or months, as shown here.

- Seconds, minutes, hours, days, weeks --> seconds, and
- months and years --> months.

This information is passed along the pipeline, getting transformed
as specified, until it reaches an end-point function: `ago`,
`from_now`, `before` or `from`.
