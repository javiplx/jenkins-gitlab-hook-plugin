require 'spec_helper'

describe "BranchSpect matching" do

  context "when branchspec is master" do
    let(:subject) { BranchSpec.new('master') }

    it "will not match when string is 'master'" do
      expect(subject.matches('master')).to be(false)
    end

    context "will match" do
      it "when string is 'origin/master'" do
        expect(subject.matches('origin/master')).to be(true)
      end
      it "when string is 'other/master'" do
        expect(subject.matches('other/master')).to be(true)
      end
      it "when string is '*/master'" do
        expect(subject.matches('*/master')).to be(true)
      end
      it "when string is 'remotes/master'" do
        expect(subject.matches('remotes/master')).to be(true)
      end
    end

    context "will not match" do
      it "when string is 'refs/remotes/master'" do
        expect(subject.matches('refs/remotes/master')).to be(false)
      end
      it "when string is 'refs/remotes/origin/master'" do
        expect(subject.matches('refs/remotes/origin/master')).to be(false)
      end
      it "when string is 'remotes/origin/master'" do
        expect(subject.matches('remotes/origin/master')).to be(false)
      end
      it "when string is 'origin/otherbranch'" do
        expect(subject.matches('origin/otherbranch')).to be(false)
      end
      it "when string is '*/otherbranch'" do
        expect(subject.matches('*/otherbranch')).to be(false)
      end
      it "when string is '*'" do
        expect(subject.matches('*')).to be(false)
      end
      it "when string is '**'" do
        expect(subject.matches('**')).to be(false)
      end
    end

  end

  context "when branchspec is origin/*" do
    let(:subject) { BranchSpec.new('origin/*') }

    context "will match" do
      it "when string is 'origin/*'" do
        expect(subject.matches('origin/*')).to be(true)
      end
      it "when string is 'origin/master'" do
        expect(subject.matches('origin/master')).to be(true)
      end
      it "when string is 'origin/otherbranch'" do
        expect(subject.matches('origin/otherbranch')).to be(true)
      end
    end

    context "will not match" do
      it "when string is 'master'" do
        expect(subject.matches('master')).to be(false)
      end
      it "when string is 'refs/remotes/master'" do
        expect(subject.matches('refs/remotes/master')).to be(false)
      end
      it "when string is 'remotes/master'" do
        expect(subject.matches('remotes/master')).to be(false)
      end
      it "when string is 'refs/remotes/origin/master'" do
        expect(subject.matches('refs/remotes/origin/master')).to be(false)
      end
      it "when string is 'remotes/origin/master'" do
        expect(subject.matches('remotes/origin/master')).to be(false)
      end
      it "when string is 'other/master'" do
        expect(subject.matches('other/master')).to be(false)
      end
      it "when string is '*/master'" do
        expect(subject.matches('*/master')).to be(false)
      end
      it "when string is '*/otherbranch'" do
        expect(subject.matches('*/otherbranch')).to be(false)
      end
      it "when string is '*'" do
        expect(subject.matches('*')).to be(false)
      end
      it "when string is '**'" do
        expect(subject.matches('**')).to be(false)
      end
      it "when string is '*/*'" do
        expect(subject.matches('*/*')).to be(false)
      end
      it "when string is '**/*'" do
        expect(subject.matches('**/*')).to be(false)
      end
      it "when string is '*/**'" do
        expect(subject.matches('*/**')).to be(false)
      end
    end

  end

  context "when branchspec is origin/master" do
    let(:subject) { BranchSpec.new('origin/master') }

    context "will match" do
      it "when string is 'origin/master'" do
        expect(subject.matches('origin/master')).to be(true)
      end
    end

    context "will not match" do
      it "when string is 'origin/*'" do
        expect(subject.matches('origin/*')).to be(false)
      end
      it "when string is 'origin/otherbranch'" do
        expect(subject.matches('origin/otherbranch')).to be(false)
      end
      it "when string is 'master'" do
        expect(subject.matches('master')).to be(false)
      end
      it "when string is 'other/master'" do
        expect(subject.matches('other/master')).to be(false)
      end
      it "when string is '*/master'" do
        expect(subject.matches('*/master')).to be(false)
      end
      it "when string is '*/otherbranch'" do
        expect(subject.matches('*/otherbranch')).to be(false)
      end
      it "when string is '*'" do
        expect(subject.matches('*')).to be(false)
      end
      it "when string is '**'" do
        expect(subject.matches('**')).to be(false)
      end
      it "when string is '*/*'" do
        expect(subject.matches('*/*')).to be(false)
      end
      it "when string is '**/*'" do
        expect(subject.matches('**/*')).to be(false)
      end
      it "when string is '*/**'" do
        expect(subject.matches('*/**')).to be(false)
      end
    end

  end

end
