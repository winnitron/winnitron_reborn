FactoryGirl.define do
  factory :arcade_machine do
    title    { Faker::Lorem.words(3).join(" ") }
    location { Faker::Address.city }
    players  2

    after :create do |machine|
      ApiKey.create arcade_machine: machine
      MachineOwnership.create arcade_machine: machine, user: FactoryGirl.create(:user, builder: true)
    end
  end
end