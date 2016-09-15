require 'test_helper'

module ActionController
  class Base
    def render_to_string(opts = {})
      opts.to_s
    end
  end
end

module ActionControllerMock
  class Base
    def render(_)
      [:base]
    end

    def render_to_string
    end

    def self.after_action(_)
    end
  end
end

class PdfHelperTest < ActionController::TestCase
  module SomePatch
    def render(_)
      super.tap do |s|
        s << :patched
      end
    end
  end

  def setup
    @ac = ActionController::Base.new
  end

  def teardown
    @ac = nil
  end

  test 'should prerender header and footer :template options' do
    options = @ac.send(:prerender_header_and_footer,
                       :header => { :html => { :template => 'hf.html.erb' } })
    assert_match %r{^file:\/\/\/.*wicked_header_pdf.*\.html}, options[:header][:html][:url]
  end

  test 'should not interfere with already prepended patches' do
    # Emulate railtie
    if Rails::VERSION::MAJOR >= 5
      OriginalBase = ActionController::Base
      ActionController.send(:remove_const, :Base)
      ActionController.const_set(:Base, ActionControllerMock::Base)

      # Emulate another gem being loaded before wicked
      ActionController::Base.prepend(SomePatch)
      ActionController::Base.prepend(::WickedPdf::PdfHelper)

      ac = ActionController::Base.new

      begin
        assert_equal ac.render(:cats), [:base, :patched]
      rescue SystemStackError
        assert_equal true, false # force spec failure
      ensure
        ActionController.send(:remove_const, :Base)
        ActionController.const_set(:Base, OriginalBase)
      end
    end
  end
end
