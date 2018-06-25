class AccountRegistrator

    def initialize(user, logger)
        @user = user
        @logger = logger
    end

    def get_account_info(name)
        account = GrapheneCli.instance.exec('get_account', [name])
        if account && account[0] && account[0]['id']
            return {id: account[0]['id']}
        end
        return nil
    end

    def register(account_name, owner_key, active_key, memo_key, referrer, harddrive_id, mac_address)
        @logger.info("---- Registering account: '#{account_name}' #{owner_key}/#{active_key} referrer: #{referrer}")

        if get_account_info(account_name)
            @logger.warn("---- Account exists: '#{account_name}' #{get_account_info(account_name)}")
            return {error: {'message' => 'Account exists'}}
        end

        registrar_account = Rails.application.config.faucet.registrar_account
        referrer_account = registrar_account
        referrer_percent = 0
        unless referrer.blank?
            refaccount_info = get_account_info(referrer)
            if refaccount_info
                referrer_account = referrer
                referrer_percent = Rails.application.config.faucet.referrer_percent
            else
                @logger.warn("---- Referrer '#{referrer}' does not exist")
            end
        end

        res = {}
        result, error = GrapheneCli.instance.exec('register_account', [account_name, owner_key, active_key,
                                                                       registrar_account, referrer_account,
                                                                       referrer_percent, harddrive_id, mac_address, true])
        if error
            @logger.error("!!! register_account error: #{error.inspect}")
            res[:error] = error
        else
            @logger.debug(result.inspect)
            res[:result] = result
            #GrapheneCli.instance.exec('transfer', [registrar_account, account_name, '1000', 'QBITS', 'Welcome to OpenLedger. Read more about Qbits under asset', true])
        end
        return res
    end


end
