module FacebookAds
  # An ad campaign has many ad sets and belongs to an ad account.
  # https://developers.facebook.com/docs/marketing-api/reference/ad-campaign-group
  class AdCampaign < Base
    FIELDS     = %w(id account_id buying_type can_use_spend_cap configured_status created_time effective_status name objective start_time stop_time updated_time spend_cap).freeze
    STATUSES   = %w(ACTIVE PAUSED DELETED PENDING_REVIEW DISAPPROVED PREAPPROVED PENDING_BILLING_INFO CAMPAIGN_PAUSED ARCHIVED ADSET_PAUSED).freeze
    OBJECTIVES = %w(CONVERSIONS MOBILE_APP_INSTALLS).freeze

    # belongs_to ad_account

    def ad_account
      @ad_account ||= AdAccount.find("act_#{account_id}")
    end

    # has_many ad_sets

    def ad_sets(effective_status: ['ACTIVE'], limit: 100)
      AdSet.paginate("/#{id}/adsets", query: { effective_status: effective_status, limit: limit })
    end

    def create_ad_set(name:, promoted_object:, targeting:, daily_budget:, optimization_goal:, billing_event: 'IMPRESSIONS', status: 'ACTIVE', is_autobid: true)
      raise Exception, "Optimization goal must be one of: #{AdSet::OPTIMIZATION_GOALS.to_sentence}" unless AdSet::OPTIMIZATION_GOALS.include?(optimization_goal)
      raise Exception, "Billing event must be one of: #{AdSet::BILLING_EVENTS.to_sentence}" unless AdSet::BILLING_EVENTS.include?(billing_event)

      if targeting.is_a?(Hash)
        # NOP
      else
        targeting.validate! # Will raise if invalid.
        targeting = targeting.to_hash
      end

      query = {
        campaign_id: id,
        name: name,
        targeting: targeting.to_json,
        promoted_object: promoted_object.to_json,
        optimization_goal: optimization_goal,
        daily_budget: daily_budget,
        billing_event: billing_event,
        status: status,
        is_autobid: is_autobid
      }
      ad_set = AdSet.post("/act_#{account_id}/adsets", query: query, objectify: true) # Returns an AdSet instance.
      AdSet.find(ad_set.id)
    end

    # has_many ad_insights

    def ad_insights(range: Date.today..Date.today, level: 'ad', time_increment: 1)
      query = {
        level: level,
        time_increment: time_increment,
        time_range: { 'since': range.first.to_s, 'until': range.last.to_s }
      }
      AdInsight.paginate("/#{id}/insights", query: query)
    end
  end
end
