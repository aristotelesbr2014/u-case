class CreateResponse < Micro::Service::Strict
  attributes :responder, :answers, :survey

  def call!
    survey_response = responder.survey_responses.build(
      response_text: answers[:text],
      rating: answers[:rating]
      survey: survey
    )

    return Success { attributes(:responder, :survey) } if survey_response.save

    Failure(:survey_response) { survey_response.errors }
  end
end

class AddRewardPoints < Micro::Service::Strict
  attributes :responder, :survey

  def call!
    reward_account = responder.reward_account
    reward_account.balance += survey.reward_points

    return Success { attributes(:responder, :survey) } if reward_account.save

    Failure(:reward_account) { reward_account.errors }
  end
end

class SendNotifications < Micro::Service::Strict
  attributes :responder, :survey

  def call!
    sender = survey.sender

    SurveyMailer.delay.notify_responder(responder.id)
    SurveyMailer.delay.notify_sender(sender.id)

    return Success { attributes(:survey) } if sender.add_survey_response_notification

    Failure(:sender) { sender.errors }
  end
end

ReplyToSurvey = CreateResponse >> AddRewardPoints >> SendNotifications

# or

ReplyToSurvey = Micro::Service::Pipeline[
  CreateResponse,
  AddRewardPoints,
  SendNotifications
]

# or

class ReplyToSurvey
  include Micro::Service::Pipeline

  pipeline CreateResponse, AddRewardPoints, SendNotifications
end