defmodule TimeUtils do

  @moduledoc """
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
  """

  @type nni :: non_neg_integer

  @doc "Answers the given number itself, treating it as the number of seconds."
  @spec seconds(nni) :: {:seconds, nni}
  def seconds(s), do: {:seconds, s}

  @doc "Converts the given number of minutes to seconds, and answers it."
  @spec minutes(nni) :: {:seconds, nni}
  def minutes(m), do: {:seconds, m * 60}

  @doc "Converts the given number of hours to seconds, and answers it."
  @spec hours(nni) :: {:seconds, nni}
  def hours(h), do: {:seconds, h * 3600}

  @doc "Converts the given number of days to seconds, and answers it."
  @spec days(nni) :: {:seconds, nni}
  def days(d), do: {:seconds, d * 86400}

  @doc "Converts the given number of weeks to seconds, and answers it."
  @spec weeks(nni) :: {:seconds, nni}
  def weeks(w), do: {:seconds, w * 604800}

  @doc "Answers a tuple with an atom ':months' and the given number of months."
  @spec months(nni) :: {:months, nni}
  def months(m), do: {:months, m}

  @doc "Answers a tuple with an atom ':months' and the given number of years converted to months."
  @spec years(nni) :: {:months, nni}
  def years(y), do: {:months, y * 12}

  @doc "Answers `true` if the given year is a leap year; `false` otherwise."
  @spec is_leap_year?(nni) :: boolean
  def is_leap_year?(y) do
    cond do
      0 == rem(y, 400) -> true
      0 == rem(y, 100) -> false
      0 == rem(y, 4) -> true
      true -> false
    end
  end
  
  # This is the internal work-horse function.  The end-point functions
  # utilise this function for the actual calculation.  Apart from
  # performing the requested calculation, this function handles leap
  # years and month-specific number of days.
  @spec adjust({:seconds, nni}, list) ::
    {{nni, nni, nni}, {nni, nni, nni}}
  defp adjust({:seconds, s}, opts) do
    w = case List.keyfind opts, :from, 0 do
          {:from, whence} -> whence
          _ -> :erlang.localtime
        end
    w = :erlang.localtime_to_universaltime w
    utc = :erlang.universaltime_to_posixtime(w)
    utc = case List.keyfind opts, :future, 0 do
            {:future, _} -> utc + s
            _ -> utc - s
          end
    upd = :erlang.posixtime_to_universaltime utc
    :erlang.universaltime_to_localtime upd
  end

  # This is the internal work-horse function.  The end-point functions
  # utilise this function for the actual calculation.  Apart from
  # performing the requested calculation, this function handles leap
  # years and month-specific number of days.
  @spec adjust({:months, nni}, list) ::
    {{nni, nni, nni}, {nni, nni, nni}}
  defp adjust({:months, m}, opts) do
    {{cy, cm, cd}, tm} = case List.keyfind opts, :from, 0 do
                           {:from, whence} -> case whence do
                                                {d, t} -> {d, t}
                                                d -> {d, :erlang.time}
                                              end
                           _ -> :erlang.localtime
                         end
    ccm = cy * 12 + cm
    cim = case List.keyfind opts, :future, 0 do
            {:future, _} -> ccm + m
            _ -> ccm - m
          end
    iy = div cim, 12
    im = rem cim, 12
    if im == 0 do
      iy = iy - 1
      im = 12
    end
    id = case cd do
           t when t <= 28 -> t
           t when (t >= 29 and im == 2) ->
             if is_leap_year?(iy), do: 29, else: 28
           t when t <= 30 -> t
           t when t == 31 -> if im in [4, 6, 9, 11], do: 30, else: 31
         end
    {{iy, im, id}, tm}
  end

  @doc """
    This is an end-point function.  The accumulated seconds are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  @spec ago({:seconds, nni}) ::
    {{nni, nni, nni}, {nni, nni, nni}}
  def ago({:seconds, s}) do
    adjust {:seconds, s}, []
  end

  @doc """
    This is an end-point function.  The accumulated seconds are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  @spec from_now({:seconds, nni}) ::
    {{nni, nni, nni}, {nni, nni, nni}}
  def from_now({:seconds, s}) do
    adjust {:seconds, s}, future: true
  end

  @doc """
    This is an end-point function.  The accumulated months are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  @spec ago({:months, nni}) ::
    {{nni, nni, nni}, {nni, nni, nni}}
  def ago({:months, m}) do
    adjust {:months, m}, []
  end

  @doc """
    This is an end-point function.  The accumulated months are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  @spec from_now({:months, nni}) ::
    {{nni, nni, nni}, {nni, nni, nni}}
  def from_now({:months, m}) do
    adjust {:months, m}, future: true
  end

  @doc """
    This is an end-point function.  The accumulated seconds are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  @spec before({:seconds, nni}, {{nni, nni, nni}, {nni, nni, nni}}) ::
    {{nni, nni, nni}, {nni, nni, nni}}
  def before({:seconds, s}, whence) do
    adjust {:seconds, s}, from: whence
  end

  @doc """
    This is an end-point function.  The accumulated months are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  @spec before({:months, nni}, {{nni, nni, nni}, {nni, nni, nni}}) ::
    {{nni, nni, nni}, {nni, nni, nni}}
  def before({:months, m}, whence) do
    adjust {:months, m}, from: whence
  end

  @doc """
    This is an end-point function.  The accumulated seconds are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  @spec from({:seconds, nni}, {{nni, nni, nni}, {nni, nni, nni}}) ::
    {{nni, nni, nni}, {nni, nni, nni}}
  def from({:seconds, s}, whence) do
    adjust {:seconds, s}, from: whence, future: true
  end

  @doc """
    This is an end-point function.  The accumulated months are utilised
    to perform the actual calculation using the given reference date or
    date-time.
  """
  @spec from({:months, nni}, {{nni, nni, nni}, {nni, nni, nni}}) ::
    {{nni, nni, nni}, {nni, nni, nni}}
  def from({:months, m}, whence) do
    adjust {:months, m}, from: whence, future: true
  end

  @doc "Answers the current date-time."
  def now, do: :erlang.localtime

  @doc "Answers the current date."
  def today, do: :erlang.date

  @doc "Answers yesterday's date-time."
  def yesterday, do: 1 |> days |> ago

  @doc "Answers tomorrow's date-time."
  def tomorrow, do: 1 |> days |> from_now

  @doc "Answers the date-time of a week ago."
  def last_week, do: 1 |> weeks |> ago

  @doc "Answers the date-time of a week henceforth."
  def next_week, do: 1 |> weeks |> from_now

  @doc "Answers the date-time of a month ago."
  def last_month, do: 1 |> months |> ago

  @doc "Answers the date-time of a month henceforth."
  def next_month, do: 1 |> months |> from_now

  @doc "Answers the date-time of a year ago."
  def last_year, do: 1 |> years |> ago

  @doc "Answers the date-time of a year henceforth."
  def next_year, do: 1 |> years |> from_now

end
