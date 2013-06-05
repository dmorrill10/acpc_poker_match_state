
require_relative 'support/spec_helper'

require 'acpc_dealer'
require 'acpc_poker_types/poker_action'
require 'acpc_poker_types/card'
require 'acpc_poker_match_state/players_at_the_table'

describe AcpcPokerMatchState::PlayersAtTheTable do
  describe '#update!' do
    it "keeps track of state for a sequence of match states and actions in Doyle's game" do
      # Change this number to do more or less thorough tests.
      # Some interesting three player hands occur after 120
      # Careful though, even 10 hands takes about three seconds,
      # and it scales slightly less than linearly. 120 takes
      # about 30 seconds.
      num_hands = 10
      match_logs.each do |log_description|
        @match = AcpcPokerTypes::AcpcDealerData::PokerMatchData.parse_files(
          log_description.actions_file_path,
          log_description.results_file_path,
          log_description.player_names,
          AcpcDealer::DEALER_DIRECTORY,
          num_hands
        )
        @match.for_every_seat! do |users_seat|

          @patient = AcpcPokerMatchState::PlayersAtTheTable.seat_players(
            @match.match_def.game_def,
            (@match.players.map{ |player| player.name }),
            users_seat,
            num_hands
          )

          check_patient

          @match.for_every_hand! do
            @match.for_every_turn! do
              @patient.update! @match.current_hand.current_match_state

              check_patient
            end
          end
        end
      end
    end
  end

  def check_patient(patient=@patient)
    patient.player_acting_sequence.must_equal @match.player_acting_sequence
    patient.players.length.must_equal @match.players.length
    check_last_action
    check_next_to_act
    check_last_turn
    patient.opponents_cards_visible?.must_equal @match.opponents_cards_visible?
    patient.reached_showdown?.must_equal @match.opponents_cards_visible?
    patient.less_than_two_non_folded_players?.must_equal @match.non_folded_players.length < 2

    if @match.current_hand
      patient.hand_ended?.must_equal @match.current_hand.final_turn?
      patient.match_ended?.must_equal (@match.final_hand? && @match.current_hand.final_turn?)
      unless @match.current_hand.final_turn?
        patient.transition.next_state.list_of_hole_card_hands.each do |hand|
          hand.each do |card|
            card.must_be_kind_of AcpcPokerTypes::Card
          end
        end
      end
    end
    patient.last_hand?.must_equal (
      if @match.final_hand?.nil?
        false
      else
        @match.final_hand?
      end
    )
    patient.player_acting_sequence_string.must_equal @match.player_acting_sequence_string
    patient.users_turn_to_act?.must_equal @match.users_turn_to_act?
    check_betting_sequence(patient)
    # @todo Test this eventually
    # patient.min_wager.to_i.must_equal @min_wager.to_i
  end

  def check_player_blind_relation(patient)
    x_player_blind_relation = @match.player_blind_relation
    patient.player_blind_relation.each do |player, blind|
      x_player_and_blind = x_player_blind_relation.to_a.find do |player_and_blind|
        player_and_blind.first.seat == player.seat
      end

      x_player = x_player_and_blind.first
      x_blind = x_player_and_blind.last

      player.close_enough?(x_player).must_equal true
      blind.must_equal x_blind
    end
  end
  def check_betting_sequence(patient)
    patient_betting_sequence = patient.betting_sequence.map do |actions|
      actions.map { |action| AcpcPokerTypes::PokerAction.new(action).to_s }
    end
    x_betting_sequence = @match.betting_sequence.map do |actions|
      actions.map { |action| AcpcPokerTypes::PokerAction.new(action).to_s }
    end
    patient_betting_sequence.must_equal x_betting_sequence

    patient.betting_sequence_string.scan(/([a-z]\d*|\/)/).flatten.map do |action|
      if action.match(/\//)
        action
      else
        AcpcPokerTypes::PokerAction.new(action).to_s
      end
    end.join('').must_equal @match.betting_sequence_string
  end
  def check_last_action(patient=@patient)
    if @match.current_hand && @match.current_hand.last_action
      patient.player_who_acted_last.seat.must_equal @match.current_hand.last_action.seat
    else
      patient.player_who_acted_last.must_be_nil
    end
  end
  def check_next_to_act(patient=@patient)
    if @match.current_hand && @match.current_hand.next_action
      patient.next_player_to_act.seat.must_equal @match.current_hand.next_action.seat
    else
      patient.next_player_to_act.must_be_nil
    end
  end
  def check_last_turn(patient=@patient)
    return unless @match.current_hand && @match.current_hand.final_turn?

    patient.players.players_close_enough?(@match.players).must_equal true
    patient.user_player.close_enough?(@match.player).must_equal true
    patient.opponents.players_close_enough?(@match.opponents).must_equal true
    patient.non_folded_players.players_close_enough?(@match.non_folded_players).must_equal true
    patient.active_players.players_close_enough?(@match.active_players).must_equal true
    patient.player_with_dealer_button.close_enough?(@match.player_with_dealer_button).must_equal true
    check_player_blind_relation(patient)
    patient.chip_stacks.must_equal @match.chip_stacks
    patient.chip_balances.must_equal @match.chip_balances
    patient.chip_contributions.flatten.inject(:+).must_equal @match.chip_contributions.flatten.inject(:+)
  end
end

class Array
  def players_close_enough?(other_players)
    return false if other_players.length != length
    each_with_index do |player, index|
      return false unless player.close_enough?(other_players[index])
    end
    true
  end
  def reject_empty_elements
    reject do |elem|
      elem.empty?
    end
  end
end

class AcpcPokerTypes::Player
  def acpc_actions_taken_this_hand
    acpc_actions = @actions_taken_this_hand.map do |actions_per_turn|
      actions_per_turn.map { |action| AcpcPokerTypes::PokerAction.new(action).to_s }
    end
    if acpc_actions.first.empty?
      acpc_actions
    else
      acpc_actions.reject_empty_elements
    end
  end

  def close_enough?(other)
    @name == other.name &&
    @seat == other.seat &&
    @chip_stack == other.chip_stack &&
    @chip_balance == other.chip_balance &&
    acpc_actions_taken_this_hand == other.acpc_actions_taken_this_hand
  end
end