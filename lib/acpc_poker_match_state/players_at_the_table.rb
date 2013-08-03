require 'acpc_poker_types/seat'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_match_state/player'

require 'contextual_exceptions'
using ContextualExceptions::ClassRefinement

module AcpcPokerMatchState
module MapWithIndex
  refine Array do
    def map_with_index
      i = 0
      map do |elem|
        result = yield elem, i
        i += 1
        result
      end
    end
  end
end
end
using AcpcPokerMatchState::MapWithIndex


module AcpcPokerMatchState

class PlayersAtTheTable
  include AcpcPokerTypes

  exceptions :player_acted_before_sitting_at_table,
    :no_players_to_seat, :multiple_players_have_the_same_seat

  attr_reader :players

  attr_reader :match_state

  attr_reader :number_of_hands

  attr_reader :game_def

  class << self; alias_method(:seat_players, :new) end

  # @todo Remove dependence on player_names users_seat, and number_of_hands

  # @param [GameDefinition] game_def The game definition for the
  #  match these players are playing.
  # @param [Integer] number_of_hands The number of hands in this match.
  def initialize(game_def, number_of_hands)
    @players = game_def.number_of_players.times.map do |i|
      Player.new(
        Seat.new(i, game_def.number_of_players)
      )
    end

    @users_seat = Seat.new(0, game_def.number_of_players)

    @game_def = game_def

    @number_of_hands = number_of_hands
  end

  # @param [MatchState] match_state The next match state.
  def update!(match_state)
    @match_state = match_state

    update_players!
  end

  # @return [Boolean] +true+ if the hand has ended, +false+ otherwise.
  def hand_ended?
    return false unless @match_state

    @match_state.hand_ended? @game_def
  end

  # @return [Boolean] +true+ if the match has ended, +false+ otherwise.
  def match_ended?
    hand_ended? && last_hand?
  end

  # @return [Player] The player with the dealer button.
  def dealer_player
    return nil unless @match_state
    @players.find { |player| position_relative_to_dealer(player) == @players.length - 1}
  end
  def big_blind_payer
    @players.find do |plyr|
      position_relative_to_dealer(plyr) == @game_def.blinds.index(@game_def.blinds.max)
    end
  end
  def small_blind_payer
    @players.find do |plyr|
      position_relative_to_dealer(plyr) == (
        @game_def.blinds.index do |blind|
          blind < @match.match_def.game_def.blinds.max && blind > 0
        end
      )
    end
  end
  def next_player_to_act
    return nil if @match_state.nil? || hand_ended?

    ap next_to_act: @match_state.next_to_act(@game_def)

    @players.find { |plyr| position_relative_to_dealer(plyr) == @match_state.next_to_act(@game_def) }
  end

  # @return [Boolean] +true+ if it is the user's turn to act, +false+ otherwise.
  def users_turn_to_act?
    return false if @match_state.nil? || hand_ended?

    next_player_to_act.seat == @users_seat
  end

  # @param [Integer] player The player of which the position relative to the
  #  dealer is desired.
  # @return [Integer] The position relative to the dealer of the given player,
  #  +player+, indexed such that the player immediately to to the left of the
  #  dealer has a +position_relative_to_dealer+ of zero.
  # @raise (see Integer#seat_from_relative_position)
  # @raise (see Integer#position_relative_to)
  def position_relative_to_dealer(player)
    (@users_seat.seats_to(player) + users_position_relative_to_dealer) % @players.length
  end

  # @return [Array] The set of legal actions for the currently acting player.
  def legal_actions
    return [] unless @match_state

    @match_state.players(@game_def)[users_position_relative_to_dealer].legal_actions
  end

  # @return [Boolean] +true+ if the current hand is the last in the match.
  def last_hand?
    # @todo make sure +@match_state.hand_number+ is not greater than @number_of_hands
    return false unless @match_state

    @match_state.hand_number == @number_of_hands - 1
  end

  # @return [String] player acting sequence as a string.
  def player_acting_sequence_string
    (player_acting_sequence.map { |per_round| per_round.join('') }).join('/')
  end

  # @return [Array<Array<Integer>>] The sequence of seats that acted,
  #  separated by round.
  def player_acting_sequence
    return [] unless @match_state

    @match_state.player_acting_sequence(@game_def).map do |actions_per_round|
      actions_per_round.map do |seat|
        position_relative_to_dealer(seat)
      end
    end
  end

  def users_position_relative_to_dealer
    @match_state.position_relative_to_dealer
  end

  private

  def update_players!
    return self if @match_state.first_state_of_first_round?

    @players.each do |plyr|
      plyr.hand_player = @match_state.players(@game_def)[position_relative_to_dealer(plyr)]
    end

    distribute_chips! if hand_ended?

    self
  end

  # Distribute chips to all winning players
  # @param [BoardCards] board_cards The community board cards.
  def distribute_chips!(board_cards)
    @players.each do |plyr|
      plyr.balance += plyr.hand_player.balance
    end

    self
  end
end
end