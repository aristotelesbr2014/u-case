require 'test_helper'

require_relative '../users_entity'
require_relative '../shared_assertions'

class Micro::Case::MWRF
  class Step04UsingStaticCompositionTest < Minitest::Test
    include SharedAssertions

    module Users::Creation4a
      class NormalizeParams < Micro::Case
        attributes :name, :email

        def call!
          normalized_name = String(name).strip.gsub(/\s+/, ' ')
          normalized_email = String(email).downcase.strip

          Success result: { name: normalized_name, email: normalized_email }
        end
      end
    end

    module Users::Creation4a
      require 'uri'

      class ValidateParams < Micro::Case
        attributes :name, :email

        def call!
          validation_errors = []
          validation_errors << "Name can't be blank" if name.empty?
          validation_errors << "Email is invalid" if email !~ URI::MailTo::EMAIL_REGEXP

          return Success() if validation_errors.empty?

          Failure :invalid_attributes, result: {
            errors: OpenStruct.new(full_messages: validation_errors)
          }
        end
      end
    end

    require 'securerandom'

    module Users::Creation4a
      class Persist < Micro::Case
        attributes :name, :email

        def call!
          user_data = attributes.merge(id: SecureRandom.uuid)

          Success result: { user: Users::Entity.new(user_data) }
        end
      end
    end

    module Users::Creation4a
      class SyncWithCRM < Micro::Case
        attribute :user

        def call!
          if user.persisted?
            Success result: { user: user, crm_id: sync_with_crm }
          else
            Failure :crm_error, result: { message: "User can't be sent to the CRM" }
          end
        end

        private def sync_with_crm
          # Do some integration stuff...
          SecureRandom.uuid
        end
      end
    end

    module Users::Creation4a
      Process = Micro::Cases.flow([
        NormalizeParams,
        ValidateParams,
        Persist,
        SyncWithCRM
      ])
    end

    def use_case
      Users::Creation4a::Process
    end

  end
end
