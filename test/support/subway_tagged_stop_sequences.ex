defmodule Screens.TestSupport.SubwayTaggedStopSequences do
  @moduledoc """
  Functions providing tagged stop sequences for building subway-related test data.
  """

  import Screens.TestSupport.ParentStationIdSigil

  def blue do
    %{"Blue" => [~P[wondl rbmnl bmmnl sdmnl orhte wimnl aport mvbcl aqucl state gover bomnl]]}
  end

  def orange do
    %{
      "Orange" => [
        ~P[ogmnl mlmnl welln astao sull ccmnl north haecl state dwnxg chncl tumnl bbsta masta rugg rcmnl jaksn sbmnl grnst forhl]
      ]
    }
  end

  def red, do: red(~w[ashmont braintree]a)

  def red(branches) when is_list(branches) do
    [
      :ashmont in branches and ashmont_seq(),
      :braintree in branches and braintree_seq()
    ]
    |> Enum.filter(& &1)
    |> then(&%{"Red" => &1})
  end

  def green, do: green(~w[b c d e]a)

  def green(branches) when is_list(branches) do
    [
      :b in branches and {"Green-B", [b_seq()]},
      :c in branches and {"Green-C", [c_seq()]},
      :d in branches and {"Green-D", [d_seq()]},
      :e in branches and {"Green-E", [e_seq()]}
    ]
    |> Enum.filter(& &1)
    |> Map.new()
  end

  defp ashmont_seq do
    red_trunk_seq() ++ ~P[shmnl fldcr smmnl asmnl]
  end

  defp braintree_seq do
    red_trunk_seq() ++ ~P[nqncy wlsta qnctr qamnl brntn]
  end

  defp red_trunk_seq do
    ~P[alfcl davis portr harsq cntsq knncl chmnl pktrm dwnxg sstat brdwy andrw jfk]
  end

  defp b_seq do
    ~P[gover pktrm boyls armnl coecl hymnl kencl bland buest bucen amory babck brico harvd grigg alsgr wrnst wascm sthld chswk chill sougr lake]
  end

  defp c_seq do
    ~P[gover pktrm boyls armnl coecl hymnl kencl smary hwsst kntst stpul cool sumav bndhl fbkst bcnwa tapst denrd engav clmnl]
  end

  defp d_seq do
    ~P[unsqu lech spmnl north haecl gover pktrm boyls armnl coecl hymnl kencl fenwy longw bvmnl brkhl bcnfd rsmnl chhil newto newtn eliot waban woodl river]
  end

  defp e_seq do
    ~P[mdftf balsq mgngl gilmn esomr lech spmnl north haecl gover pktrm boyls armnl coecl prmnl symcl nuniv mfa lngmd brmnl fenwd mispk rvrwy bckhl hsmnl]
  end
end
