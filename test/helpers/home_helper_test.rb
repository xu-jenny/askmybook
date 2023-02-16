require 'test_helper'

class HomeHelperTest < ActionView::TestCase
  test "vector similiarity should return expected result" do
    result = AskQuestionUtil.vector_similarity([1,1,1], [2,2,2])
    assert_equal result, 6
  end

  
end