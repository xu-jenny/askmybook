class HomeController < ApplicationController
    def load
        q = Question.all()
        puts q
        render json: { data: q }

    end
end
