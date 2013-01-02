
# Gems
require 'acpc_poker_types'

# Assortment of methods to support model tests
module ModelTestHelper
   
   # Initialization methods ---------------------------------------------------      
   def create_players(big_blind, small_blind)
      player_who_submitted_big_blind = mock('Player')
      player_who_submitted_big_blind.stubs(:current_wager_faced=).with(0)
      player_who_submitted_big_blind.stubs(:current_wager_faced).returns(0)
      player_who_submitted_big_blind.stubs(:name).returns('big_blind_player')
      
      player_who_submitted_small_blind = mock('Player')
      player_who_submitted_small_blind.stubs(:current_wager_faced=).with(big_blind - small_blind)
      player_who_submitted_small_blind.stubs(:current_wager_faced).returns(big_blind - small_blind)
      player_who_submitted_small_blind.stubs(:name).returns('small_blind_player')
      
      other_player = mock('Player')
      other_player.stubs(:current_wager_faced=).with(big_blind)
      other_player.stubs(:current_wager_faced).returns(big_blind)
      other_player.stubs(:name).returns('other_player')
      
      [player_who_submitted_big_blind, player_who_submitted_small_blind, other_player]
   end
      
   def setup_action_test(match_state, action_type, action_argument = '')
      action = action_argument + action_type
      expected_string = raw_match_state match_state, action
      
      expected_string
   end
   
   
   # Helper methods -----------------------------------------------------------

   def raw_match_state(match_state, action)
      "#{match_state}:#{action}"
   end
   
   # Construct an arbitrary hole card hand.
   #
   # @return [Mock Hand] An arbitrary hole card hand.
   def arbitrary_hole_card_hand
      hand = mock('Hand')
      hand_as_string = AcpcPokerTypes::CARD_RANKS[:two]
         + AcpcPokerTypes::CARD_SUITS[:spades][:acpc_character]
         + AcpcPokerTypes::CARD_RANKS[:three]
         + AcpcPokerTypes::CARD_SUITS[:hearts][:acpc_character]
      hand.stubs(:to_str).returns(hand_as_string)
      hand.stubs(:to_s).returns(hand_as_string)
      
      hand
   end
end