defmodule Poker.Card do
  defstruct value: nil, suit: nil

  def render_hidden do
    "🂠"
  end

  def render(nil) do
    ""
  end

  def render(%Poker.Card{value: v, suit: s}) do
    case {v,s} do
      {1 ,:hearts} -> "🂱"
      {2 ,:hearts} -> "🂲"
      {3 ,:hearts} -> "🂳"
      {4 ,:hearts} -> "🂴"
      {5 ,:hearts} -> "🂵"
      {6 ,:hearts} -> "🂶"
      {7 ,:hearts} -> "🂷"
      {8 ,:hearts} -> "🂸"
      {9 ,:hearts} -> "🂹"
      {10,:hearts} -> "🂺"
      {11,:hearts} -> "🂻"
      {12,:hearts} -> "🂽"
      {13,:hearts} -> "🂾"

      {1 ,:spades} -> "🂡"
      {2 ,:spades} -> "🂢"
      {3 ,:spades} -> "🂣"
      {4 ,:spades} -> "🂤"
      {5 ,:spades} -> "🂥"
      {6 ,:spades} -> "🂦"
      {7 ,:spades} -> "🂧"
      {8 ,:spades} -> "🂨"
      {9 ,:spades} -> "🂩"
      {10,:spades} -> "🂪"
      {11,:spades} -> "🂫"
      {12,:spades} -> "🂭"
      {13,:spades} -> "🂮"

      {1 ,:diamonds} -> "🃁"
      {2 ,:diamonds} -> "🃂"
      {3 ,:diamonds} -> "🃃"
      {4 ,:diamonds} -> "🃄"
      {5 ,:diamonds} -> "🃅"
      {6 ,:diamonds} -> "🃆"
      {7 ,:diamonds} -> "🃇"
      {8 ,:diamonds} -> "🃈"
      {9 ,:diamonds} -> "🃉"
      {10,:diamonds} -> "🃊"
      {11,:diamonds} -> "🃋"
      {12,:diamonds} -> "🃍"
      {13,:diamonds} -> "🃎"

      {1 ,:clubs} -> "🃑"
      {2 ,:clubs} -> "🃒"
      {3 ,:clubs} -> "🃓"
      {4 ,:clubs} -> "🃔"
      {5 ,:clubs} -> "🃕"
      {6 ,:clubs} -> "🃖"
      {7 ,:clubs} -> "🃗"
      {8 ,:clubs} -> "🃘"
      {9 ,:clubs} -> "🃙"
      {10,:clubs} -> "🃚"
      {11,:clubs} -> "🃛"
      {12,:clubs} -> "🃝"
      {13,:clubs} -> "🃞"
    end
  end
end
