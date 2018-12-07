class BtsAccount < ActiveRecord::Base
  DATE_SCOPES = ['Today', 'Yesterday', 'This week', 'Last week', 'This month', 'Last month', 'All']

  belongs_to :user

  validates :name, presence: true
  validates :owner_key, presence: true
  validates :active_key, presence: true
  #validates :memo_key, presence: true

  validates_uniqueness_of :remote_ip, conditions: -> {where("created_at > '#{(DateTime.now - 1.hour).to_s(:db)}'")}, message: "Can't register more than one account per IP in less than 1 hour"

  before_create :register_account

  scope :grouped_by_referrers, -> { select([:referrer, 'count(*) as count']).group(:referrer).order('count desc') }

    def self.dates_range(scope_name)
        return nil if scope_name == 'All' || !scope_name.in?(DATE_SCOPES)
        case scope_name
             when 'Today'
               Date.today.beginning_of_day..Date.today.end_of_day
             when 'Yesterday'
               (Date.today - 1.day).beginning_of_day..(Date.today - 1.day).end_of_day
             when 'This week'
               Date.today.at_beginning_of_week.beginning_of_day..Date.today.end_of_day
             when 'Last week'
               1.week.ago.at_beginning_of_week..1.week.ago.at_end_of_week
             when 'This month'
               Date.today.at_beginning_of_month..Date.today
             when 'Last month'
               1.month.ago.at_beginning_of_month..1.month.ago.at_end_of_month
           end
  end

  private

  def register_account
    result = AccountRegistrator.new(nil, logger).register(self.name, self.owner_key, self.active_key, self.memo_key, self.referrer)
    if result[:error]
      errors.add(:base, result[:error]['message'] ? result[:error]['message'] : 'unknown backend error')
      return false
    end
    return true
  end


end
