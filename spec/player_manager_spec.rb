
require File.expand_path('../support/spec_helper', __FILE__)

# Local classes
require File.expand_path('../../src/player_manager', __FILE__)

describe PlayerManager do   
   
   describe '#manage' do
      it 'creates players with names and starting stack amounts as given' do
         #player_names_to_stack_map = {'p1' => 100, 'p2' => 200}
         #patient = PlayerManager.manage player_names_to_stack_map
         #
         #player_names = patient.players.map { |player| player.name }
         #player_stacks = patient.players.map { |player| player.chip_stack.to_i }
         #
         #player_names.should be == player_names_to_stack_map.keys
         #player_stacks.should be == player_names_to_stack_map.values
         pending 'Updates to MatchstateString'
      end
      it 'assigns zero as a stack amount if none is given' do
         pending 'Updates to MatchstateString'
      end
      it 'raises an exception if it was given no players to manage' do
         expect{PlayerManager.manage({}, mock('MatchstateString'))}.to raise_exception(PlayerManager::NoPlayersToManage)
      end
   end
   
end