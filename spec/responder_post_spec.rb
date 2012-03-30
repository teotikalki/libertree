require 'spec_helper'

describe Libertree::Server::Responder::Post do
  describe 'rsp_post' do

    context 'when the requester has not INTRODUCEd itself' do
      it 'returns ERROR' do
        @s.process 'POST { "anything": "anything" }'
        @s.should have_responded_with_code('ERROR')
        @s.response['message'].should =~ /introduce/i
      end
    end

    context 'with a known requester' do
      before :each do
        @requester = Libertree::Model::Server.create(
          FactoryGirl.attributes_for(:server).merge(
            { :public_key => $test_public_key }
          )
        )
      end

      context 'when the requester has INTRODUCEd itself' do
        before :each do
          @s.stub(:challenge_new) { 'abcdefghijklmnopqrstuvwxyz' }
          @s.process %<INTRODUCE { "public_key": #{$test_public_key.to_json} } >
        end

        context 'when the requester has not AUTHENTICATEd itself' do
          it 'returns ERROR' do
            @s.process 'POST { "anything": "anything" }'
            @s.should have_responded_with_code('ERROR')
            @s.response['message'].should =~ /authenticate/i
          end
        end

        context 'when the requester has AUTHENTICATEd itself' do
          before :each do
            @s.process 'AUTHENTICATE { "response": "abcdefghijklmnopqrstuvwxyz" }'
            @s.should have_responded_with_code('OK')
          end

          context 'and the member is known' do
            before :each do
              @member = Libertree::Model::Member.create(
                FactoryGirl.attributes_for(:member, :server_id => @requester.id)
              )
            end

            it 'with a missing id it responds with MISSING PARAMETER' do
              h = {
                'username' => @member.username,
                'public'      => true,
                'text'        => 'A test post.',
              }
              @s.process "POST #{h.to_json}"
              @s.should have_responded_with_code('MISSING PARAMETER')
            end


            it 'with a blank id it responds with MISSING PARAMETER' do
              h = {
                'username' => @member.username,
                'id'        => '',
                'public'      => true,
                'text'        => 'A test post.',
              }
              @s.process "POST #{h.to_json}"
              @s.should have_responded_with_code('MISSING PARAMETER')
            end

            it "with a member username that isn't found" do
              h = {
                'username' => 'nosuchusername',
                'id'       => 4,
                'public'   => true,
                'text'     => 'A test post.',
              }
              @s.process "POST #{h.to_json}"
              @s.should have_responded_with_code('NOT FOUND')
            end

            context 'with valid post data, and a member that does not belong to the requester' do
              before :each do
                other_server = Libertree::Model::Server.create(
                  FactoryGirl.attributes_for(:server).merge(
                    { :public_key => $test_public_key }
                  )
                )
                @member = Libertree::Model::Member.create(
                  FactoryGirl.attributes_for(:member, :server_id => other_server.id)
                )
              end

              it 'responds with NOT FOUND' do
                h = {
                  'username' => @member.username,
                  'id'       => 5,
                  'public'   => true,
                  'text'     => 'A test post.',
                }
                @s.process "POST #{h.to_json}"
                @s.should have_responded_with_code('NOT FOUND')
              end
            end

            it 'with valid data it responds with OK' do
              h = {
                'username' => @member.username,
                'id'       => 6,
                'public'   => true,
                'text'     => 'A test post.',
              }
              @s.process "POST #{h.to_json}"
              @s.should have_responded_with_code('OK')
            end
          end
        end
      end
    end
  end
end
