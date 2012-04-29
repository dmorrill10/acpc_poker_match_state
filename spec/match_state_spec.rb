
require File.expand_path('../support/spec_helper', __FILE__)

# Local modules
#require File.expand_path('../support/model_test_helper', __FILE__)

# Local classes
require File.expand_path('../../src/match_state', __FILE__)

describe MatchState do
   #include ModelTestHelper
   
   pending "Since this class has so much state and uses so many classes, it's really hard to test and I can't think of a good way to do it yet."
   
   #describe 'Given the holdem.nolimit.2p.reverse_blinds.game game definition' do
   #   game_definition = mock 'GameDefinition'
   #   game_definition.stubs(:small_blind).returns(5)
   #   game_definition.stubs(:big_blind).returns(10)
   #   game_definition.stubs(:list_of_blinds).returns([10, 5])
   #   game_definition.stubs(:number_of_hole_cards).returns(2)
   #   game_definition.stubs(:number_of_ranks).returns(13)
   #   game_definition.stubs(:number_of_suits).returns(4)
   #   game_definition.stubs(:list_of_player_stacks).returns([500, 500])
   #   game_definition.stubs(:max_raise_in_each_round).returns([3, 4, 4, 4])
   #   game_definition.stubs(:first_player_position_in_each_round).returns([2, 1, 1, 1])
   #   game_definition.stubs(:minimum_wager_in_each_round)
   #   game_definition.stubs(:number_of_board_cards_in_each_round)
   #   game_definition.stubs(:number_of_rounds)
   #   game_definition.stubs(:number_of_players)
   #   game_definition.stubs(:betting_type)      
   #end
   #before(:each) do
   #   @game_definition = create_game_definition
   #   
   #   @players = []
   #   @game_definition.number_of_players.times do |i|
   #      @players << mock('Player')
   #      @players[i].stubs(:is_active?).returns(true)
   #      @players[i].stubs(:is_all_in=).with(false)
   #      @players[i].stubs(:has_folded=).with(false)
   #      @players[i].stubs(:has_folded).returns(false)
   #      @players[i].stubs(:position_relative_to_dealer).returns(i)
   #      @players[i].stubs(:stack).returns(@game_definition.list_of_player_stacks[i])
   #      @players[i].stubs(:stack=).with(@game_definition.list_of_player_stacks[i])
   #      @players[i].stubs(:current_wager_faced=).with(@game_definition.big_blind)
   #      @players[i].stubs(:call_current_wager!)
   #      @players[i].stubs(:hole_cards=)
   #   end      
   #   
   #   big_blind_player = @players[player_who_submitted_big_blind_index]
   #   big_blind_player.stubs(:current_wager_faced=).with(0)
   #   big_blind_player.stubs(:current_wager_faced).returns(0)
   #   big_blind_player.stubs(:name).returns('big_blind_player')
   #   
   #   small_blind_player = @players[player_who_submitted_small_blind_index]
   #   small_blind_player.stubs(:current_wager_faced=).with(@game_definition.big_blind - @game_definition.small_blind)
   #   small_blind_player.stubs(:current_wager_faced).returns(0)
   #   small_blind_player.stubs(:name).returns('small_blind_player')
   #   #
   #   # TODO Find all the other players that didn't submit a blind
   #   #other_player.stubs(:current_wager_faced=).with(big_blind)
   #   #other_player.stubs(:current_wager_faced).returns(0)
   #   #other_player.stubs(:name).returns('other_player')
   #   
   #   @position_relative_to_dealer_next_to_act = 1
   #   
   #   start_new_game! @game_definition, @players
   #end
   #
   #
   # Properly reports state ###################################################
   
   #it 'properly reports which player has the dealer button' do
   #   match_state_string = mock('MatchstateString')
   #   
   #   player_names = "p1, p2"
   #   number_of_hands = 1
   #   
   #   patient = MatchState.new game_def, match_state_string, player_names, number_of_hands
   #   
   #   player_with_the_dealer_button = @players[player_with_the_dealer_button_index]
   #   
   #   @patient.player_with_the_dealer_button.should be player_with_the_dealer_button
   #end
   #
   #it 'properly reports which player submitted the big blind' do
   #   player_who_submitted_big_blind = @players[player_who_submitted_big_blind_index]
   #   
   #   @patient.player_who_submitted_big_blind.should be player_who_submitted_big_blind
   #end
   #
   #it 'properly reports which player submitted the small blind' do
   #   player_who_submitted_small_blind = @players[player_who_submitted_small_blind_index]
   #   
   #   @patient.player_who_submitted_small_blind.should be player_who_submitted_small_blind
   #end
   #
   #it 'properly reports which player is next to act' do
   #   player_whose_turn_is_next = @players[player_whose_turn_is_next_index]
   #   
   #   @patient.player_whose_turn_is_next.should be player_whose_turn_is_next
   #end
   #
   #it 'properly reports which player acted last' do
   #   player_who_acted_last = nil
   #   @patient.player_who_acted_last.should be player_who_acted_last
   #   
   #   @match_state.stubs(:last_action).returns(ACTION_TYPES[:call])
   #   @patient.update_state! @match_state
   #   @position_relative_to_dealer_acted_last = 1
   #   player_who_acted_last = @players[player_who_acted_last_index]
   #   
   #   @patient.player_who_acted_last.should be player_who_acted_last
   #end
   #
   #it 'properly reports the pot size' do
   #   pending
   #   #@patient.pot_size.should be pot_size
   #end
   #
   #it "properly reports stack sizes at the beginning of a hand" do
   #   pending
   #   @patient.list_of_player_stacks.should == @game_definition.list_of_player_stacks
   #end
   #
   #it "properly resets stack sizes at the beginning of a hand in Doyle's game" do
   #   @patient.list_of_player_stacks.should be == @game_definition.list_of_player_stacks
   #   pending "change the stack sizes, then start a new hand and check that they have reset"
   #end
   #
   #it "properly reports the user's hole cards" do
   #   pending
   #   @patient.users_hole_cards.should be @match_state.users_hole_cards
   #end
   #
   #it "properly reports the hole cards of the user's opponents" do
   #   pending
   #   @patient.list_of_opponents_hole_cards.should be @match_state.list_of_opponents_hole_cards
   #end
   #
   #it 'properly reports the betting actions for each player' do
   #   pending
   #   @patient.list_of_betting_actions.should be @match_state.list_of_betting_actions
   #end
   #
   #it 'properly reports the board cards' do
   #   pending
   #   @patient.list_of_board_cards.should be @match_state.list_of_board_cards
   #end
   #
   #it 'properly reports the hand number' do
   #   pending
   #   @patient.hand_number.should be @match_state.hand_number
   #end
   #
   #it "properly reports the user's position" do
   #   pending
   #   @patient.user_position.should be @match_state.position_relative_to_dealer
   #end
   #
   #it 'properly reports the last action' do
   #   pending
   #   @patient.last_action.should be @match_state.last_action
   #end
   #
   #it 'properly reports the list of legal actions' do
   #   pending
   #   @patient.legal_actions.should be legal_actions
   #end
   #
   #it "properly reports the round number for all rounds in Texas Hold'em" do
   #   for_every_round do |round|
   #      @patient.round.should be == round
   #   end
   #end
   #
   #it 'properly reports the active players' do
   #   pending
   #   @patient.active_players.should be @active_players
   #end
   #
   #it "properly reports whether or not it is the user's turn next at the beginning of every round in Texas Hold'em" do
   #   for_every_round do |round|
   #      @player_manager.stubs(:users_turn_to_act?).returns(@game_definition.first_player_position_in_each_round[round]-1 == @user_position)
   #      @patient.users_turn_to_act?.should be == (@game_definition.first_player_position_in_each_round[round]-1 == @user_position)
   #   end
   #end
   #
   #
   #it "correctly reports the first player to act for all rounds in Texas Hold'em" do
   #   for_every_round do |round|
   #      @patient.position_relative_to_dealer_next_to_act.should == @game_definition.first_player_position_in_each_round[round]-1
   #   end
   #end
   #
   #it "correctly reports the whether or not the user is the first player to act for all rounds in Texas Hold'em" do
   #   for_every_round do |round|
   #      @patient.users_turn_to_act?.should == (@user_position == @game_definition.first_player_position_in_each_round[round]-1)
   #   end
   #end
   #
   #
   ## Updates state based on opponent actions ##################################
   #
   #it 'at the beginning of a hand, the current wager should be the big blind for all players except those who submitted a blind' do
   #   #@patient.player.should be ==
   #   pending
   #end
   #
   #it 'at the beginning of a hand, the current wager for the player who submitted the small blind should be big blind minus small blind' do
   #   pending
   #   #@patient.player_who_submitted_small_blind.current_wager_faced.should be == @game_definition.big_blind - @game_definition.small_blind
   #end
   #
   #it 'at the beginning of a hand, the current wager for the player who submitted the big blind should be zero' do
   #   pending
   #   #@patient.player_who_submitted_big_blind.current_wager_faced.should be == 0
   #end   
   #
   #it "updates the current wager faced by all players when a raise or bet is seen" do
   #   pending
   #end
   #
   #it "updates state based on call or check" do
   #   pending
   #   #amount = '9001'
   #   #action = amount + ACTION_TYPES[:raise]
   #   #expected_string = raw_match_state_string action
   #   #@patient.take_bet_action(amount).should be == expected_string
   #   #TODO check that the user's stack is updated correctly
   #end
   #
   #it "updates state based on fold" do
   #   pending
   #   #amount = '9001'
   #   #action = amount + ACTION_TYPES[:raise]
   #   #expected_string = raw_match_state_string action
   #   #@patient.take_bet_action(amount).should be == expected_string
   #   #TODO check that the user's stack is updated correctly
   #end
   #
   #it "updates state based on limit raise or bet" do
   #   pending
   #   expected_string = setup_action_test @match_state, ACTION_TYPES[:raise]
   #   @patient.make_raise_or_bet_action
   #   
   #   first_player_position = @game_definition.first_player_position_in_each_round[0] - 1
   #   raise_size = @game_definition.minimum_wager_in_each_round[0]
   #   player_stack = @game_definition.list_of_player_stacks[first_player_position] - raise_size
   #   list_of_player_stacks = @game_definition.list_of_player_stacks.dup
   #   list_of_player_stacks[first_player_position] = player_stack
   #   
   #   pending "need to adjust for current wager"
   #   @patient.list_of_player_stacks.should be == list_of_player_stacks
   #end
   #
   #it "updates state based on no-limit raise or bet" do
   #   pending
   #   #amount = '9001'
   #   #action = amount + ACTION_TYPES[:raise]
   #   #expected_string = raw_match_state_string action
   #   #@patient.take_bet_action(amount).should be == expected_string
   #   #TODO check that the user's stack is updated correctly
   #end
   #
   #
   ## Helper methods ###########################################################
   #
   #def for_every_round
   #   MAX_VALUES[:rounds].times do |round|
   #      @match_state.stubs(:round).returns(round)
   #      @match_state.stubs(:number_of_actions_in_current_round).returns(0)
   #      
   #      @patient.update_state! @match_state
   #      
   #      yield round
   #   end
   #end
   #
   #def start_new_game!(game_definition, players)
   #   @patient = PlayerManager.new game_definition, players
   #   (@match_state, @user_position) = create_initial_match_state(game_definition.number_of_players)
   #   
   #   @patient.start_new_hand! @match_state
   #end
   #
   #def dealer_position_relative_to_dealer
   #   @game_definition.number_of_players - 1
   #end
   #
   #def player_with_the_dealer_button_index
   #   @players.index { |player| dealer_position_relative_to_dealer == player.position_relative_to_dealer }
   #end
   #
   #def player_who_submitted_big_blind_index
   #   big_blind_position = if is_reverse_blinds? then BLIND_POSITIONS_RELATIVE_TO_DEALER_REVERSE_BLINDS[:submits_big_blind] else BLIND_POSITIONS_RELATIVE_TO_DEALER_NORMAL_BLINDS[:submits_big_blind] end
   #   @players.index { |player| player.position_relative_to_dealer == big_blind_position }
   #end
   #
   #def player_who_submitted_small_blind_index
   #   small_blind_position = if is_reverse_blinds? then BLIND_POSITIONS_RELATIVE_TO_DEALER_REVERSE_BLINDS[:submits_small_blind] else BLIND_POSITIONS_RELATIVE_TO_DEALER_NORMAL_BLINDS[:submits_small_blind] end
   #   @players.index { |player| player.position_relative_to_dealer == small_blind_position }
   #end
   #
   #def player_whose_turn_is_next_index
   #   @players.index { |player| player.position_relative_to_dealer == @position_relative_to_dealer_next_to_act }
   #end
   #
   #def player_who_acted_last_index
   #   @players.index { |player| player.position_relative_to_dealer == @position_relative_to_dealer_acted_last }
   #end
   #
   #def is_reverse_blinds?
   #   2 == @game_definition.number_of_players
   #end
end