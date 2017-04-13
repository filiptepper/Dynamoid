require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Dynamoid::Criteria do
  let!(:user1) {User.create(:name => 'Josh', :email => 'josh@joshsymonds.com', admin: true)}
  let!(:user2) {User.create(:name => 'Justin', :email => 'justin@joshsymonds.com', admin: false)}

  it 'finds first using where' do
    expect(User.where(:name => 'Josh').first).to eq user1
  end

  it 'finds all using where' do
    expect(User.where(:name => 'Josh').all).to eq [user1]
  end

  context "transforms booleans" do
    it 'accepts native' do
      expect(User.where(:admin => 't').all).to eq [user1]
    end

    it 'accepts string' do
      expect(User.where(:admin => 'true').all).to eq [user1]
    end

    it 'accepts boolean' do
      expect(User.where(:admin => true).all).to eq [user1]
    end
  end

  it 'returns all records' do
    expect(Set.new(User.all)).to eq Set.new([user1, user2])
    expect(User.all.first.new_record).to be_falsey
  end

  context 'Magazine table' do
    before(:each) do
      Magazine.create_table
    end

    it 'returns empty attributes for where' do
      expect(Magazine.where(:name => 'Josh').all).to eq []
    end

    it 'returns empty attributes for all' do
      expect(Magazine.all).to eq []
    end
  end

  it 'passes each to all members' do
    User.each do |u|
      expect(u.id == user1.id || u.id == user2.id).to be_truthy
      expect(u.new_record).to be_falsey
    end
  end

  it 'returns N records' do
    5.times { |i| User.create(:name => 'Josh', :email => 'josh_#{i}@joshsymonds.com') }
    expect(User.eval_limit(2).all.size).to eq(2)
  end

  # TODO: This test is broken using the AWS SDK adapter.
  # it 'start with a record' do
  #  5.times { |i| User.create(:name => 'Josh', :email => 'josh_#{i}@joshsymonds.com') }
  #  all = User.all
  #  expect(User.start(all[3]).all).to eq(all[4..-1])

  #  all = User.where(:name => 'Josh').all
  #  expect(User.where(:name => 'Josh').start(all[3]).all).to eq(all[4..-1])
  # end

  context 'User table' do
    before(:each) do
      User.create_table
      Tweet.create_table
    end

    it 'send consistent option to adapter' do
      expect(Dynamoid.adapter).to receive(:scan) { |table_name, key, options| expect(options[:consistent_read]).to be(true) }.and_return([])
      User.where(:name => 'x').consistent.first

      expect(Dynamoid.adapter).to receive(:query) { |table_name, options| expect(options[:consistent_read]).to be(true) }.and_return([])
      Tweet.where(:tweet_id => 'xx', :group => 'two').consistent.all

      expect(Dynamoid.adapter).to receive(:query) { |table_name, options| expect(options[:consistent_read]).to be(false) }.and_return([])
      Tweet.where(:tweet_id => 'xx', :group => 'two').all
    end
  end
end
