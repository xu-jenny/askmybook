class HomeController < ApplicationController
    def load
        filepath = './embeddings.csv'
        $embedding = helpers.load_embedding_csv(filepath)
        p "Finish loading embedding"
    end
    def ask
        answer = helpers.ask(ask_params[:question], $embedding)
        puts answer
        render json: { answer: answer }
    end
    def ask_params
        params.permit(:question)
    end
end
