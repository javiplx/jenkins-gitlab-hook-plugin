require 'spec_helper'

require 'models/root_action_descriptor'

module GitlabWebHook
  describe ProcessMergeRequest do

    context 'with cross-repo merge request' do
      let(:details) { double(MergeRequestDetails, source_project_id: '14', target_project_id: '15') }
      it 'raise exception' do
        expect { subject.with(details) }.to raise_exception(BadRequestException)
      end
    end

  end
end
