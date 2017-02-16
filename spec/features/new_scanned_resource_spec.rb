require 'rails_helper'

RSpec.feature "ScannedResourcesController", type: :feature do
  let(:user) { FactoryGirl.create(:image_editor) }
  let(:workflow) { Sipity::Workflow.find_by(name: 'book_works') }
  let(:identifier) { instance_double(Ezid::Identifier, id: 'ark:/99999/fk4wtest') }

  context "an authorized user" do
    before do
      allow(Ezid::Identifier).to receive(:mint).and_return(identifier)
    end

    before(:each) do
      sign_in user
    end

    scenario "Logged in user can create a new scanned resource and advance workflow state", vcr: { cassette_name: "locations" } do
      visit new_polymorphic_path [ScannedResource]
      expect(page).to_not have_selector("label.label-warning", text: "Pending")

      fill_in 'scanned_resource_title', with: 'Test Title'
      expect(page).to have_select 'scanned_resource_rights_statement', selected: 'No Known Copyright'
      expect(page).to have_select 'scanned_resource_pdf_type', selected: 'Grayscale PDF'
      click_button 'Create Scanned resource'

      expect(page).to have_selector("h1", text: "Test Title")
      expect(page).to have_selector("span.label-default", text: "Pending")
      expect(page).to have_text("No Known Copyright")

      Hyrax::Workflow::PermissionGenerator.call(agents: user, roles: 'admin', workflow: workflow)
      visit current_path

      choose 'Metadata Review'
      click_button 'Submit'

      choose 'Final Review'
      click_button 'Submit'

      choose 'Complete'
      click_button 'Submit'

      expect(page).to have_selector("li.identifier", text: "ark:/99999/fk4wtest")

      choose "Takedown"
      click_button "Submit"

      choose "Complete"
      click_button "Submit"

      choose "Flagged"
      click_button "Submit"

      expect(page).to have_selector("span.label-warning", text: "Flagged")
    end
  end

  context "an anonymous user" do
    scenario "Anonymous user can't create a scanned resource" do
      visit new_polymorphic_path [ScannedResource]
      expect(page).to have_selector("div.alert-info", text: "You are not authorized to access this page")
    end
  end
end
