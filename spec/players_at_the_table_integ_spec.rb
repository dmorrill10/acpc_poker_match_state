
require File.expand_path('../support/spec_helper', __FILE__)

require 'acpc_dealer'
require 'acpc_dealer_data'

require File.expand_path('../../lib/acpc_poker_match_state/players_at_the_table', __FILE__)

describe PlayersAtTheTable do
  describe '#update!' do
    it "keeps track of state for a sequence of match states and actions in Doyle's game" do
      num_hands = 15
      match_logs.each do |log_description|
        @match = PokerMatchData.parse_files(
          log_description.actions_file_path,
          log_description.results_file_path,
          log_description.player_names,
          AcpcDealer::DEALER_DIRECTORY,
          num_hands
        )
        @match.for_every_seat! do |users_seat|

          @patient = PlayersAtTheTable.seat_players(
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
    patient.player_acting_sequence.should == @match.player_acting_sequence
    patient.number_of_players.should == @match.players.length
    if @match.current_hand && @match.current_hand.last_action
      patient.player_who_acted_last.seat.should == @match.current_hand.last_action.seat
    else
      patient.player_who_acted_last.should be nil
    end
    if @match.current_hand && @match.current_hand.next_action
      patient.next_player_to_act.seat.should == @match.current_hand.next_action.seat
    else
      patient.next_player_to_act.should be nil
    end
    if @match.current_hand && @match.current_hand.final_turn?
      patient.players.players_close_enough?(@match.players).should == true
      patient.user_player.close_enough?(@match.player).should == true
      patient.opponents.players_close_enough?(@match.opponents).should == true
      patient.non_folded_players.players_close_enough?(@match.non_folded_players).should == true
      patient.active_players.players_close_enough?(@match.active_players).should == true
      patient.player_with_dealer_button.close_enough?(@match.player_with_dealer_button).should == true
      check_player_blind_relation(patient)
      patient.chip_stacks.should == @match.chip_stacks
      patient.chip_balances.should == @match.chip_balances
      patient.chip_contributions.sum.should == @match.chip_contributions.sum
    end
    patient.opponents_cards_visible?.should == @match.opponents_cards_visible?
    patient.reached_showdown?.should == @match.opponents_cards_visible?
    patient.less_than_two_non_folded_players?.should == @match.non_folded_players.length < 2
    if @match.current_hand
      patient.hand_ended?.should == @match.current_hand.final_turn?
      patient.match_ended?.should == (@match.final_hand? && @match.current_hand.final_turn?)
    end
    patient.last_hand?.should == if @match.final_hand?.nil?
      false
    else
      @match.final_hand?
    end
    patient.player_acting_sequence_string.should == @match.player_acting_sequence_string
    patient.users_turn_to_act?.should == @match.users_turn_to_act?
    check_betting_sequence(patient)
    # @todo Test this eventually
    # patient.min_wager.to_i.should == @min_wager.to_i
  end

  def check_player_blind_relation(patient)
    expected_player_blind_relation = @match.player_blind_relation
    patient.player_blind_relation.each do |player, blind|
      expected_player_and_blind = expected_player_blind_relation.to_a.find do |player_and_blind| 
        player_and_blind.first.seat == player.seat
      end

      expected_player = expected_player_and_blind.first
      expected_blind = expected_player_and_blind.last

      player.close_enough?(expected_player).should == true
      blind.should == expected_blind
    end
  end
  def check_betting_sequence(patient)
    patient_betting_sequence = patient.betting_sequence.map do |actions| 
        actions.map { |action| action.to_low_res_acpc }
    end
    expected_betting_sequence = @match.betting_sequence.map do |actions| 
      actions.map { |action| action.to_low_res_acpc }
    end
    patient_betting_sequence.should == expected_betting_sequence
    
    patient.betting_sequence_string.scan(/([a-z]\d*|\/)/).flatten.map do |action| 
      if action.match(/\//)
        action
      else
        PokerAction.new(action).to_low_res_acpc
      end
    end.join('').should == @match.betting_sequence_string
  end
end


# @todo Move these into utils

require 'awesome_print'
 
# @param [#to_s] message The message to log.
def log_message(message)
  puts message.to_s
end

def debug(variables)
  log_message variables.awesome_inspect
end

############

class Array
  def players_close_enough?(other_players)
    # puts "length: #{length}, other: #{other_players.length}"

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

# @todo Move these into their respective classes
class PokerMatchData
  # @todo Untested
  # @return [String] player acting sequence as a string.
  def player_acting_sequence_string
    (player_acting_sequence.map { |per_round| per_round.join('') }).join('/')
  end
  def users_turn_to_act?
    return false unless current_hand && current_hand.next_action
    current_hand.next_action.seat == @seat
  end
  def betting_sequence
    sequence = [[]]
    
    if (
      @hand_number.nil? || 
      current_hand.turn_number.nil? || 
      current_hand.turn_number < 1
    )
      return sequence
    end
      
    turns_taken = current_hand.data[0..current_hand.turn_number-1]
    turns_taken.each_with_index do |turn, turn_index|
      next unless turn.action_message

      sequence[turn.action_message.state.round] << turn.action_message.action

      if (
        new_round?(sequence.length - 1 , turn_index) ||
        players_all_in?(sequence.length - 1, turn_index, turns_taken)
      )
        sequence << []
      end
    end

    sequence
  end
  def betting_sequence_string
    (betting_sequence.map do |per_round|
       (per_round.map{|action| action.to_acpc}).join('')
    end).join('/')
  end
  # @todo Test and implement this
  # def min_wager
  #   return nil unless current_hand

  #   @match_def.game_def.min_wagers[current_hand.next_state.round]
  #   ChipStack.new [@min_wager.to_i, action_with_context.amount_to_put_in_pot.to_i].max
  # end
end
class PokerAction
  # @return [Hash] Map of specific to general actions to more specific actions (e.g. check to call and bet to raise).
  LOW_RESOLUTION_ACTION_CONVERSION = {call: :call, raise: :raise, fold: :fold, check: :call, bet: :raise}

  def to_low_res_acpc
    LEGAL_ACTIONS[LOW_RESOLUTION_ACTION_CONVERSION[@symbol]] + @modifier.to_s
  end
end
class Player
  def acpc_actions_taken_this_hand
    acpc_actions = @actions_taken_this_hand.map do |actions_per_turn| 
      actions_per_turn.map { |action| action.to_low_res_acpc }
    end
    if acpc_actions.first.empty?
      acpc_actions
    else
      acpc_actions.reject_empty_elements
    end
  end

  def close_enough?(other)
    # puts "name: #{name == other.name}"
    # puts "seat: #{seat == other.seat}"
    # puts "chip_stack: #{chip_stack}, other: #{other.chip_stack}"
    # puts "chip balances: #{chip_balance}, other: #{other.chip_balance}"
    # puts "actions_taken_this_hand: #{acpc_actions_taken_this_hand}, other: #{other.acpc_actions_taken_this_hand}"
    # puts "all_in: #{all_in?}, other: #{other.all_in?}"


    @name == other.name &&
    @seat == other.seat && 
    @chip_stack == other.chip_stack &&
    @chip_balance == other.chip_balance &&
    acpc_actions_taken_this_hand == other.acpc_actions_taken_this_hand
  end
end