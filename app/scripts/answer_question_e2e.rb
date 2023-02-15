require 'pdf-reader'
require "ruby/openai"
require 'csv'
require 'matrix'

$client = OpenAI::Client.new(access_token: ENV['OPENAI_ACCESS_KEY'])
EMBEDDING_MODEL="text-embedding-ada-002"
COMPLETIONS_MODEL = "text-davinci-003"
MAX_SECTION_LEN = 1000


def get_embedding(text, model)
    $client.embeddings(
        parameters: {
            model: model,
            input: text
        }
    )
end

def print_embedding(embedding)
    embedding.each do |page|
        puts "page #{page[0]} tokens: #{page[2]} len_embed: #{page[1].length()}"
    end
end

def compute_doc_embedding_by_page(reader, embedding, start, last)
    reader.pages[start..last].each_with_index do |page, index|
        if(page.text.length() > 0)
            content = page.text.split.join(" ")
            result = get_embedding(page.text, EMBEDDING_MODEL)    # get_embedding returns number of tokens
            if result.key?("data")
                puts "index+start:#{index+start}, #{content[0,10]}, #{result["data"][0]["embedding"].length()}"
                embedding << [index+start, result["data"][0]["embedding"], result['usage']['total_tokens'], content]
            end
        end
    end
    return embedding
end

def compute_doc_embedding(book_filename, csv_filename)
    CSV.open(csv_filename, 'a') do |csv|
        reader = PDF::Reader.new(book_filename)
        start_index = 5
        while start_index < reader.pages.length() do
            embedding = Array.new()
            compute_doc_embedding_by_page(reader, embedding, start_index, start_index+29)
            start_index += 30
            sleep 300   # sleeping to account for API limits
        end
    end
end

# compute_doc_embedding("book.pdf", "embedding.csv")

##### order by relevance
def vector_similarity(x, y)
    return Vector.send(:new, x).inner_product(Vector.send(:new, y))
end

def order_document_sections_by_query_similarity(query, context)
    data = get_embedding(query, EMBEDDING_MODEL)
    query_embedding = data["data"][0]["embedding"]
    document_similarities = Hash.new()
    context.each do |key, page|
        sim = vector_similarity(query_embedding, page[0])
        document_similarities[key] = sim
    end
    sorted_docs = document_similarities.sort_by {|k,v| v}
    return sorted_docs.reverse.to_h
end

def load_embedding_csv(filepath)
    embedding = CSV.read(filepath)
    hash = Hash.new()
    embedding.each do |page|
        hash[page[0]] = [page[1].gsub("[", "").gsub("]", "").split(/\s*,\s*/).map(&:to_f), page[2], page[3]]
    end
    return hash
end

$embedding = load_embedding_csv("embedding.csv")
puts order_document_sections_by_query_similarity("Is Gumroad Profitable?", $embedding)

