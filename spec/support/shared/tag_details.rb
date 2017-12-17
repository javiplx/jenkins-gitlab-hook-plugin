RSpec.shared_context 'tag_details' do
  let (:tag_payload) { JSON.parse(File.read('spec/fixtures/default_tag.json')) }
  let (:tag_details) { GitlabWebHook::PayloadRequestDetails.new(tag_payload) }
end
