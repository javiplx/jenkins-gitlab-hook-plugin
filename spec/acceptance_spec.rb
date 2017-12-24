require 'spec_helper'

require 'tmpdir'
require 'fileutils'
require 'pathname'

Autologin.enable

$stdout.sync = true

feature 'GitLab 7.x' do

  testrepodir = Dir.mktmpdir [ 'testrepo' , '.git' ]
  specificdir = Dir.mktmpdir [ 'specific' , '.git' ]
  tagsrepodir = Dir.mktmpdir [ 'tagsrepo' , '.git' ]
  multiscmdir = Dir.mktmpdir [ 'multiscm' , '.git' ]
  altrepodir  = Dir.mktmpdir [ 'altrepo'  , '.git' ]
  xtrarepodir = Dir.mktmpdir [ 'xtrarepo' , '.git' ]
  repodirs = [ testrepodir , tagsrepodir , multiscmdir , altrepodir , xtrarepodir ]

  before(:all) do
    FileUtils.cp_r Dir.glob("spec/fixtures/testrepo.git/*"), testrepodir
    FileUtils.cp_r Dir.glob("spec/fixtures/testrepo.git/*"), specificdir
    File.open('work/jobs/specificjob/config.xml', 'w') do |outfd|
      outfd.write File.read('work/jobs/specificjob/config.xml.erb') % { specificdir: specificdir }
    end
    FileUtils.cp_r Dir.glob("spec/fixtures/testrepo.git/*"), tagsrepodir
    File.open('work/jobs/tagbuilder/config.xml', 'w') do |outfd|
      outfd.write( File.read('work/jobs/tagbuilder/config.xml.erb') % { tagsrepodir: tagsrepodir } )
    end
    FileUtils.cp_r Dir.glob("spec/fixtures/testrepo.git/*"), multiscmdir
    FileUtils.cp_r Dir.glob("spec/fixtures/testrepo.git/*"), altrepodir
    File.open('work/jobs/multiscm/config.xml', 'w') do |outfd|
      outfd.write File.read('work/jobs/multiscm/config.xml.erb') % { multiscmdir1: altrepodir , multiscmdir2: multiscmdir }
    end
    FileUtils.cp_r Dir.glob("spec/fixtures/testrepo.git/*"), xtrarepodir
    File.open('work/jobs/subdirjob/config.xml', 'w') do |outfd|
      outfd.write File.read('work/jobs/subdirjob/config.xml.erb') % { xtrarepodir: xtrarepodir }
    end
    @server = Jenkins::Server.new
    @gitlab = GitLabMockup.new repodirs
  end

  after(:all) do
    FileUtils.remove_dir altrepodir
    FileUtils.remove_dir multiscmdir
    FileUtils.remove_dir xtrarepodir
    FileUtils.remove_dir tagsrepodir
    FileUtils.remove_dir specificdir
    FileUtils.remove_dir testrepodir
    @server.kill
    @gitlab.kill
  end

  # Fixture payloads generated on gitlab 7.2.2
  feature 'Template based creation' do

    scenario 'Finds fallback template' do
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_simplejob']")
    end

    scenario 'Does not create project for tag' do
      incoming_payload 'tag', testrepodir
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo_tag1']")
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo_']")
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo']")
    end

    scenario 'Creates project from template' do
      incoming_payload 'first_push', testrepodir
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo']")
      wait_for '/job/testrepo', "//a[@href='/job/testrepo/1/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo/1/']")
      wait_idle
      expect(@server.result('testrepo', 1)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo')).to eq '/comment/e3719eaab95642a63e90da0b9b23de0c9d384785 - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo/1/)'
    end

    scenario 'Does nothing for tags' do
      incoming_payload 'tag', testrepodir
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo_tag1']")
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo_']")
      wait_idle
      visit '/job/testrepo'
      expect(page).not_to have_xpath("//a[@href='/job/testrepo/2/']")
    end

    scenario 'Builds a push to master branch' do
      File.write("#{testrepodir}/refs/heads/master", '6957dc21ae95f0c70931517841a9eb461f94548c')
      incoming_payload 'master_push', testrepodir
      wait_for '/job/testrepo', "//a[@href='/job/testrepo/2/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo/2/']")
      wait_idle
      expect(@server.result('testrepo', 2)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo')).to eq '/comment/6957dc21ae95f0c70931517841a9eb461f94548c - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo/2/)'
    end

  end

  feature 'Automatic project creation' do

    scenario 'Finds cloneable project' do
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo']")
    end

    scenario 'Creates project for new branch' do
      incoming_payload 'branch_creation', testrepodir
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo_feature_branch']")
      wait_for '/job/testrepo_feature_branch', "//a[@href='/job/testrepo_feature_branch/1/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo_feature_branch/1/']")
      wait_idle
      expect(@server.result('testrepo_feature_branch', 1)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo')).to eq '/comment/80a89e1156d5d7e9471c245ccaeafb7bcb49c0a5 - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo_feature_branch/1/)'
    end

    scenario 'Builds a push to feature branch' do
      File.write("#{testrepodir}/refs/heads/feature/branch", 'ba46b858929aec55a84a9cb044e988d5d347b8de')
      incoming_payload 'branch_push', testrepodir
      wait_for '/job/testrepo_feature_branch', "//a[@href='/job/testrepo_feature_branch/2/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo_feature_branch/2/']")
      wait_idle
      expect(@server.result('testrepo_feature_branch', 2)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo')).to eq '/comment/ba46b858929aec55a84a9cb044e988d5d347b8de - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo_feature_branch/2/)'
    end

    scenario 'Branch removal' do
      incoming_payload 'branch_deletion', testrepodir
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo_feature_branch']")
    end

  end

  feature 'When a specific project is triggered' do

    scenario 'Finds fallback template' do
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_simplejob']")
    end

    scenario 'Builds the given project' do
      incoming_payload 'branch_creation', specificdir, 'specificjob'
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_specificjob']")
      wait_for '/job/specificjob', "//a[@href='/job/specificjob/1/']"
      expect(page).to have_xpath("//a[@href='/job/specificjob/1/']")
      wait_idle
      expect(@server.result('specificjob', 1)).to eq 'SUCCESS'
    end

    scenario 'Does not autocreate project' do
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_specific_feature_branch']")
    end

  end

  feature 'Tag building' do

    scenario 'Trigger build for tags' do
      incoming_payload 'tag', tagsrepodir
      wait_for '/job/tagbuilder', "//a[@href='/job/tagbuilder/1/']"
      expect(page).to have_xpath("//a[@href='/job/tagbuilder/1/']")
      wait_idle
      expect(@server.result('tagbuilder', 1)).to eq 'SUCCESS'
      expect(@gitlab.last('tagsrepo')).to eq '/comment/c1a1e6918fdbf9fe49ad70060508abcc88b876d4 - [Jenkins CI result SUCCESS](http://localhost:8080/job/tagbuilder/1/)'
    end

    scenario 'Does not autocreate projects when only tag project exists' do
      incoming_payload 'first_push', tagsrepodir
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_tagsrepo_master']")
    end

  end

  feature 'Multiple SCMs jobs' do

    scenario 'Builds standard push' do
      incoming_payload 'first_push', multiscmdir
      wait_for '/job/multiscm', "//a[@href='/job/multiscm/1/']"
      expect(page).to have_xpath("//a[@href='/job/multiscm/1/']")
      wait_idle
      expect(@server.result('multiscm', 1)).to eq 'SUCCESS'
      expect(@gitlab.last('multiscm')).to eq '/comment/e3719eaab95642a63e90da0b9b23de0c9d384785 - [Jenkins CI result SUCCESS](http://localhost:8080/job/multiscm/1/)'
    end

  end

  feature 'Legacy (<7.4.3) merge request handling' do

    scenario 'Finds cloneable project' do
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo']")
    end

    scenario 'Create project with merge request' do
      incoming_payload 'legacy/merge_request', testrepodir
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo-mr-feature_branch']")
      wait_for '/job/testrepo-mr-feature_branch', "//a[@href='/job/testrepo-mr-feature_branch/1/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo-mr-feature_branch/1/']")
      wait_idle
      expect(@server.result('testrepo-mr-feature_branch', 1)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo')).to eq '/mr_comment/0 - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo-mr-feature_branch/1/)'
    end

    scenario 'Remove project once merged' do
      incoming_payload 'legacy/accept_merge_request', testrepodir
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo-mr-feature_branch']")
      wait_idle
    end

  end

  feature 'Merge request handling' do

    scenario 'Finds cloneable project' do
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo']")
    end

    scenario 'Create project with merge request' do
      incoming_payload 'merge_request', testrepodir
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo-mr-feature_branch']")
      wait_for '/job/testrepo-mr-feature_branch', "//a[@href='/job/testrepo-mr-feature_branch/1/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo-mr-feature_branch/1/']")
      wait_idle
      expect(@server.result('testrepo-mr-feature_branch', 1)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo')).to eq '/mr_comment/0 - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo-mr-feature_branch/1/)'
    end

    scenario 'Builds a push to merged branch (master)' do
      File.write("#{testrepodir}/refs/heads/master", '6957dc21ae95f0c70931517841a9eb461f94548c')
      incoming_payload 'master_push', testrepodir
      wait_for '/job/testrepo-mr-feature_branch', "//a[@href='/job/testrepo-mr-feature_branch/2/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo-mr-feature_branch/2/']")
      wait_idle
      expect(@server.result('testrepo-mr-feature_branch', 2)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo')).to eq '/mr_comment/0 - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo-mr-feature_branch/2/)'
    end

    scenario 'Remove project once merged' do
      incoming_payload 'accept_merge_request', testrepodir
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo-mr-feature_branch']")
      wait_idle
    end

  end

  feature 'Report commit status' do

    scenario 'Enables build status report' do
      page.driver.headers = { 'Accept-Language' => 'en' }
      visit '/configure'
      check '_.commit_status'
      click_button 'Apply'
      sleep 5
    end

    scenario 'Post status for push' do
      incoming_payload 'master_push', testrepodir
      wait_for '/job/testrepo', "//a[@href='/job/testrepo/4/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo/4/']")
      wait_idle
      expect(@server.result('testrepo', 3)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo')).to eq '/status/6957dc21ae95f0c70931517841a9eb461f94548c - success - http://localhost:8080/job/testrepo/4/'
    end

    feature 'Post status to commit on merged branch' do

      scenario 'when push is done on merged branch' do
        incoming_payload 'merge_request', testrepodir
        visit '/'
        expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo-mr-feature_branch']")
        wait_for '/job/testrepo-mr-feature_branch', "//a[@href='/job/testrepo-mr-feature_branch/1/']"
        expect(page).to have_xpath("//a[@href='/job/testrepo-mr-feature_branch/1/']")
        wait_idle
        expect(@server.result('testrepo-mr-feature_branch', 1)).to eq 'SUCCESS'
        expect(@gitlab.last('testrepo')).to eq '/status/ba46b858929aec55a84a9cb044e988d5d347b8de - success - http://localhost:8080/job/testrepo-mr-feature_branch/1/'
      end

      scenario 'when push is done on merge destination branch' do
        File.write("#{testrepodir}/refs/heads/master", '6957dc21ae95f0c70931517841a9eb461f94548c')
        incoming_payload 'master_push', testrepodir
        wait_for '/job/testrepo-mr-feature_branch', "//a[@href='/job/testrepo-mr-feature_branch/2/']"
        expect(page).to have_xpath("//a[@href='/job/testrepo-mr-feature_branch/2/']")
        wait_idle
        expect(@server.result('testrepo-mr-feature_branch', 2)).to eq 'SUCCESS'
        expect(@gitlab.last('testrepo')).to eq '/status/ba46b858929aec55a84a9cb044e988d5d347b8de - success - http://localhost:8080/job/testrepo-mr-feature_branch/2/'
      end

    end

    feature 'when cloning to subdir' do

      scenario 'Post status for push' do
        incoming_payload 'master_push', xtrarepodir
        wait_for '/job/subdirjob', "//a[@href='/job/subdirjob/1/']"
        expect(page).to have_xpath("//a[@href='/job/subdirjob/1/']")
        wait_idle
        expect(@server.result('subdirjob', 1)).to eq 'SUCCESS'
        expect(@gitlab.last('xtrarepo')).to eq '/status/e3719eaab95642a63e90da0b9b23de0c9d384785 - success - http://localhost:8080/job/subdirjob/1/'
      end

      scenario 'Post status to source branch commit' do
        File.write("#{xtrarepodir}/refs/heads/master", '6957dc21ae95f0c70931517841a9eb461f94548c')
        File.write("#{xtrarepodir}/refs/heads/feature/branch", 'ba46b858929aec55a84a9cb044e988d5d347b8de')
        incoming_payload 'merge_request', xtrarepodir
        visit '/'
        expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_subdirjob-mr-feature_branch']")
        wait_for '/job/subdirjob-mr-feature_branch', "//a[@href='/job/subdirjob-mr-feature_branch/1/']"
        expect(page).to have_xpath("//a[@href='/job/subdirjob-mr-feature_branch/1/']")
        wait_idle
        expect(@server.result('subdirjob-mr-feature_branch', 1)).to eq 'SUCCESS'
        expect(@gitlab.last('xtrarepo')).to eq '/status/ba46b858929aec55a84a9cb044e988d5d347b8de - success - http://localhost:8080/job/subdirjob-mr-feature_branch/1/'
      end

    end

  end

end

feature 'GitLab 8.x' do

  testrepo8xdir = Dir.mktmpdir [ 'testrepo8x' , '.git' ]
  specific8xdir = Dir.mktmpdir [ 'specific8x' , '.git' ]
  tagsrepo8xdir = Dir.mktmpdir [ 'tagsrepo8x' , '.git' ]
  multiscm8xdir = Dir.mktmpdir [ 'multiscm8x' , '.git' ]
  altrepo8xdir  = Dir.mktmpdir [ 'altrepo8x'  , '.git' ]
  xtrarepo8xdir = Dir.mktmpdir [ 'xtrarepo8x' , '.git' ]
  repodirs = [ testrepo8xdir , tagsrepo8xdir , multiscm8xdir , altrepo8xdir , xtrarepo8xdir ]

  before(:all) do
    config = File.read('work/gitlab-hook-GitlabNotifier.xml')
    File.open('work/gitlab-hook-GitlabNotifier.xml', 'w') do |outfd|
      outfd.write config.gsub(/localhost:4567/ , 'localhost:14567')
    end
    [ testrepo8xdir , specific8xdir , tagsrepo8xdir , multiscm8xdir , altrepo8xdir , xtrarepo8xdir ].each do |repodir|
      FileUtils.cp_r Dir.glob("spec/fixtures/testrepo.git/*"), repodir
    end
    [ 'specificjob8x' , 'tagbuilder8x' , 'multiscm8x' , 'subdirjob8x' ].each do |jobdir|
      Dir.mkdir "work/jobs/#{jobdir}"
    end
    File.open('work/jobs/specificjob8x/config.xml', 'w') do |outfd|
      outfd.write File.read('work/jobs/specificjob/config.xml.erb') % { specificdir: specific8xdir }
    end
    File.open('work/jobs/tagbuilder8x/config.xml', 'w') do |outfd|
      outfd.write( File.read('work/jobs/tagbuilder/config.xml.erb') % { tagsrepodir: tagsrepo8xdir } )
    end
    File.open('work/jobs/multiscm8x/config.xml', 'w') do |outfd|
      outfd.write File.read('work/jobs/multiscm/config.xml.erb') % { multiscmdir1: altrepo8xdir , multiscmdir2: multiscm8xdir }
    end
    File.open('work/jobs/subdirjob8x/config.xml', 'w') do |outfd|
      outfd.write File.read('work/jobs/subdirjob/config.xml.erb') % { xtrarepodir: xtrarepo8xdir }
    end
    @server = Jenkins::Server.new
    @gitlab = GitLabMockup.new repodirs, 14567
  end

  after(:all) do
    [ testrepo8xdir , specific8xdir , tagsrepo8xdir , multiscm8xdir , altrepo8xdir , xtrarepo8xdir ].each do |repodir|
      FileUtils.remove_dir repodir
    end
    @server.kill
    @gitlab.kill
  end

  feature 'Template based creation' do

    scenario 'Finds fallback template' do
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_simplejob']")
    end

    scenario 'Does not create project for tag' do
      incoming_payload '8x/tag', testrepo8xdir
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x_tag1']")
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x_']")
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x']")
    end

    scenario 'Creates project from template' do
      incoming_payload '8x/first_push', testrepo8xdir
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x']")
      wait_for '/job/testrepo8x', "//a[@href='/job/testrepo8x/1/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo8x/1/']")
      wait_idle
      expect(@server.result('testrepo8x', 1)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo8x')).to eq '/comment/e3719eaab95642a63e90da0b9b23de0c9d384785 - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo8x/1/)'
    end

    scenario 'Does nothing for tags' do
      incoming_payload '8x/tag', testrepo8xdir
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x_tag1']")
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x_']")
      wait_idle
      visit '/job/testrepo8x'
      expect(page).not_to have_xpath("//a[@href='/job/testrepo8x/2/']")
    end

    scenario 'Builds a push to master branch' do
      File.write("#{testrepo8xdir}/refs/heads/master", '6957dc21ae95f0c70931517841a9eb461f94548c')
      incoming_payload '8x/master_push', testrepo8xdir
      wait_for '/job/testrepo8x', "//a[@href='/job/testrepo8x/2/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo8x/2/']")
      wait_idle
      expect(@server.result('testrepo8x', 2)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo8x')).to eq '/comment/6957dc21ae95f0c70931517841a9eb461f94548c - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo8x/2/)'
    end

  end

  feature 'Automatic project creation' do

    scenario 'Finds cloneable project' do
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x']")
    end

    scenario 'Creates project for new branch' do
      incoming_payload '8x/branch_creation', testrepo8xdir
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x_feature_branch']")
      wait_for '/job/testrepo8x_feature_branch', "//a[@href='/job/testrepo8x_feature_branch/1/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo8x_feature_branch/1/']")
      wait_idle
      expect(@server.result('testrepo8x_feature_branch', 1)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo8x')).to eq '/comment/80a89e1156d5d7e9471c245ccaeafb7bcb49c0a5 - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo8x_feature_branch/1/)'
    end

    scenario 'Builds a push to feature branch' do
      File.write("#{testrepo8xdir}/refs/heads/feature/branch", 'ba46b858929aec55a84a9cb044e988d5d347b8de')
      incoming_payload '8x/branch_push', testrepo8xdir
      wait_for '/job/testrepo8x_feature_branch', "//a[@href='/job/testrepo8x_feature_branch/2/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo8x_feature_branch/2/']")
      wait_idle
      expect(@server.result('testrepo8x_feature_branch', 2)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo8x')).to eq '/comment/ba46b858929aec55a84a9cb044e988d5d347b8de - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo8x_feature_branch/2/)'
    end

    scenario 'Branch removal' do
      incoming_payload '8x/branch_deletion', testrepo8xdir
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x_feature_branch']")
    end

  end

  feature 'When a specific project is triggered' do

    scenario 'Finds fallback template' do
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_simplejob']")
    end

    scenario 'Builds the given project' do
      incoming_payload '8x/branch_creation', specific8xdir, 'specificjob8x'
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_specificjob8x']")
      wait_for '/job/specificjob8x', "//a[@href='/job/specificjob8x/1/']"
      expect(page).to have_xpath("//a[@href='/job/specificjob8x/1/']")
      wait_idle
      expect(@server.result('specificjob8x', 1)).to eq 'SUCCESS'
    end

    scenario 'Does not autocreate project' do
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_specific8x_feature_branch']")
    end

  end

  feature 'Tag building' do

    scenario 'Trigger build for tags' do
      incoming_payload '8x/tag', tagsrepo8xdir
      wait_for '/job/tagbuilder8x', "//a[@href='/job/tagbuilder8x/1/']"
      expect(page).to have_xpath("//a[@href='/job/tagbuilder8x/1/']")
      wait_idle
      expect(@server.result('tagbuilder8x', 1)).to eq 'SUCCESS'
      expect(@gitlab.last('tagsrepo8x')).to eq '/comment/c1a1e6918fdbf9fe49ad70060508abcc88b876d4 - [Jenkins CI result SUCCESS](http://localhost:8080/job/tagbuilder8x/1/)'
    end

    scenario 'Does not autocreate projects when only tag project exists' do
      incoming_payload '8x/first_push', tagsrepo8xdir
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_tagsrepo8x_master']")
    end

  end

  feature 'Multiple SCMs jobs' do

    scenario 'Builds standard push' do
      incoming_payload '8x/first_push', multiscm8xdir
      wait_for '/job/multiscm8x', "//a[@href='/job/multiscm8x/1/']"
      expect(page).to have_xpath("//a[@href='/job/multiscm8x/1/']")
      wait_idle
      expect(@server.result('multiscm8x', 1)).to eq 'SUCCESS'
      expect(@gitlab.last('multiscm8x')).to eq '/comment/e3719eaab95642a63e90da0b9b23de0c9d384785 - [Jenkins CI result SUCCESS](http://localhost:8080/job/multiscm8x/1/)'
    end

  end

  feature 'Merge request handling' do

    scenario 'Finds cloneable project' do
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x']")
    end

    scenario 'Create project with merge request' do
      incoming_payload '8x/merge_request', testrepo8xdir
      visit '/'
      expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x-mr-feature_branch']")
      wait_for '/job/testrepo8x-mr-feature_branch', "//a[@href='/job/testrepo8x-mr-feature_branch/1/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo8x-mr-feature_branch/1/']")
      wait_idle
      expect(@server.result('testrepo8x-mr-feature_branch', 1)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo8x')).to eq '/mr_comment/0 - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo8x-mr-feature_branch/1/)'
    end

    scenario 'Builds a push to merged branch (master)' do
      File.write("#{testrepo8xdir}/refs/heads/master", '6957dc21ae95f0c70931517841a9eb461f94548c')
      incoming_payload '8x/master_push', testrepo8xdir
      wait_for '/job/testrepo8x-mr-feature_branch', "//a[@href='/job/testrepo8x-mr-feature_branch/2/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo8x-mr-feature_branch/2/']")
      wait_idle
      expect(@server.result('testrepo8x-mr-feature_branch', 2)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo8x')).to eq '/mr_comment/0 - [Jenkins CI result SUCCESS](http://localhost:8080/job/testrepo8x-mr-feature_branch/2/)'
    end

    scenario 'Remove project once merged' do
      incoming_payload '8x/accept_merge_request', testrepo8xdir
      visit '/'
      expect(page).not_to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x-mr-feature_branch']")
      wait_idle
    end

  end

  feature 'Report commit status' do

    scenario 'Enables build status report' do
      page.driver.headers = { 'Accept-Language' => 'en' }
      visit '/configure'
      check '_.commit_status'
      click_button 'Apply'
      sleep 5
    end

    scenario 'Post status for push' do
      incoming_payload '8x/master_push', testrepo8xdir
      wait_for '/job/testrepo8x', "//a[@href='/job/testrepo8x/4/']"
      expect(page).to have_xpath("//a[@href='/job/testrepo8x/4/']")
      wait_idle
      expect(@server.result('testrepo8x', 4)).to eq 'SUCCESS'
      expect(@gitlab.last('testrepo8x')).to eq '/status/6957dc21ae95f0c70931517841a9eb461f94548c - success - http://localhost:8080/job/testrepo8x/4/'
    end

    feature 'Post status to commit on merged branch' do

      scenario 'when push is done on merged branch' do
        incoming_payload '8x/merge_request', testrepo8xdir
        visit '/'
        expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_testrepo8x-mr-feature_branch']")
        wait_for '/job/testrepo8x-mr-feature_branch', "//a[@href='/job/testrepo8x-mr-feature_branch/1/']"
        expect(page).to have_xpath("//a[@href='/job/testrepo8x-mr-feature_branch/1/']")
        wait_idle
        expect(@server.result('testrepo8x-mr-feature_branch', 1)).to eq 'SUCCESS'
        expect(@gitlab.last('testrepo8x')).to eq '/status/ba46b858929aec55a84a9cb044e988d5d347b8de - success - http://localhost:8080/job/testrepo8x-mr-feature_branch/1/'
      end

      scenario 'when push is done on merge destination branch' do
        File.write("#{testrepo8xdir}/refs/heads/master", '6957dc21ae95f0c70931517841a9eb461f94548c')
        incoming_payload '8x/master_push', testrepo8xdir
        wait_for '/job/testrepo8x-mr-feature_branch', "//a[@href='/job/testrepo8x-mr-feature_branch/2/']"
        expect(page).to have_xpath("//a[@href='/job/testrepo8x-mr-feature_branch/2/']")
        wait_idle
        expect(@server.result('testrepo8x-mr-feature_branch', 2)).to eq 'SUCCESS'
        expect(@gitlab.last('testrepo8x')).to eq '/status/ba46b858929aec55a84a9cb044e988d5d347b8de - success - http://localhost:8080/job/testrepo8x-mr-feature_branch/2/'
      end

    end

    feature 'when cloning to subdir' do

      scenario 'Post status for push' do
        incoming_payload '8x/master_push', xtrarepo8xdir
        wait_for '/job/subdirjob8x', "//a[@href='/job/subdirjob8x/1/']"
        expect(page).to have_xpath("//a[@href='/job/subdirjob8x/1/']")
        wait_idle
        expect(@server.result('subdirjob8x', 1)).to eq 'SUCCESS'
        expect(@gitlab.last('xtrarepo8x')).to eq '/status/e3719eaab95642a63e90da0b9b23de0c9d384785 - success - http://localhost:8080/job/subdirjob8x/1/'
      end

      scenario 'Post status to source branch commit' do
        File.write("#{xtrarepo8xdir}/refs/heads/master", '6957dc21ae95f0c70931517841a9eb461f94548c')
        File.write("#{xtrarepo8xdir}/refs/heads/feature/branch", 'ba46b858929aec55a84a9cb044e988d5d347b8de')
        incoming_payload '8x/merge_request', xtrarepo8xdir
        visit '/'
        expect(page).to have_xpath("//table[@id='projectstatus']/tbody/tr[@id='job_subdirjob8x-mr-feature_branch']")
        wait_for '/job/subdirjob8x-mr-feature_branch', "//a[@href='/job/subdirjob8x-mr-feature_branch/1/']"
        expect(page).to have_xpath("//a[@href='/job/subdirjob8x-mr-feature_branch/1/']")
        wait_idle
        expect(@server.result('subdirjob8x-mr-feature_branch', 1)).to eq 'SUCCESS'
        expect(@gitlab.last('xtrarepo8x')).to eq '/status/ba46b858929aec55a84a9cb044e988d5d347b8de - success - http://localhost:8080/job/subdirjob8x-mr-feature_branch/1/'
      end

    end

  end

end
