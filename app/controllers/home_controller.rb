class HomeController < ApplicationController
    def load
        q = Question.all()
        puts q
        render json: { data: q }
    end
    def index
        filepath = './embeddings.csv'
        $embedding = helpers.load_embedding_csv(filepath)
        answer = helpers.ask("Is Gumroad Profitable?", $embedding)
        puts answer
    end
end
