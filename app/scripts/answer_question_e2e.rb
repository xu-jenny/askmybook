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


### construct query prompt
def choose_sections(embedding, most_relevant_document_sections)
    chosen_sections_len = 0
    chosen_sections = []
    chosen_sections_indexes = []    # used for understanding
    most_relevant_document_sections.each do |key, relevance|
        chosen_sections_indexes << key
        # find embedding row by first column
        row = embedding[key]
        tokens = Integer(row[1])
        chosen_sections_len += tokens
        if chosen_sections_len >= MAX_SECTION_LEN
            break
        end
        chosen_sections << row[2]
    end
    # puts "pages chosen: " + chosen_sections_indexes
    # puts "number of tokens: " + chosen_sections_len
    return chosen_sections
end

def construct_query_promopt(embedding, question)
    most_relevant_document_sections = order_document_sections_by_query_similarity(question, embedding)
    chosen_sections = choose_sections(embedding, most_relevant_document_sections)

    header = """Sahil Lavingia is the founder and CEO of Gumroad, and the author of the book The Minimalist Entrepreneur (also known as TME). These are questions and answers by him. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful, pulled from The Minimalist Entrepreneur:\n"""

    questions = ["\n\n\nQ: How to choose what business to start?\n\nA: First off don't be in a rush. Look around you, see what problems you or other people are facing, and solve one of these problems if you see some overlap with your passions or skills. Or, even if you don't see an overlap, imagine how you would solve that problem anyway. Start super, super small.",
    "\n\n\nQ: Q: Should we start the business on the side first or should we put full effort right from the start?\n\nA:   Always on the side. Things start small and get bigger from there, and I don't know if I would ever “fully” commit to something unless I had some semblance of customer traction. Like with this product I'm working on now!",
    "\n\n\nQ: Should we sell first than build or the other way around?\n\nA: I would recommend building first. Building will teach you a lot, and too many people use “sales” as an excuse to never learn essential skills like building. You can't sell a house you can't build!",
    "\n\n\nQ: Andrew Chen has a book on this so maybe touché, but how should founders think about the cold start problem? Businesses are hard to start, and even harder to sustain but the latter is somewhat defined and structured, whereas the former is the vast unknown. Not sure if it's worthy, but this is something I have personally struggled with\n\nA: Hey, this is about my book, not his! I would solve the problem from a single player perspective first. For example, Gumroad is useful to a creator looking to sell something even if no one is currently using the platform. Usage helps, but it's not necessary.",
    "\n\n\nQ: What is one business that you think is ripe for a minimalist Entrepreneur innovation that isn't currently being pursued by your community?\n\nA: I would move to a place outside of a big city and watch how broken, slow, and non-automated most things are. And of course the big categories like housing, transportation, toys, healthcare, supply chain, food, and more, are constantly being upturned. Go to an industry conference and it's all they talk about! Any industry…",
    "\n\n\nQ: How can you tell if your pricing is right? If you are leaving money on the table\n\nA: I would work backwards from the kind of success you want, how many customers you think you can reasonably get to within a few years, and then reverse engineer how much it should be priced to make that work.",
    "\n\n\nQ: Why is the name of your book 'the minimalist entrepreneur' \n\nA: I think more people should start businesses, and was hoping that making it feel more “minimal” would make it feel more achievable and lead more people to starting-the hardest step.",
    "\n\n\nQ: How long it takes to write TME\n\nA: About 500 hours over the course of a year or two, including book proposal and outline.",
    "\n\n\nQ: What is the best way to distribute surveys to test my product idea\n\nA: I use Google Forms and my email list / Twitter account. Works great and is 100% free.",
    "\n\n\nQ: How do you know, when to quit\n\nA: When I'm bored, no longer learning, not earning enough, getting physically unhealthy, etc… loads of reasons. I think the default should be to “quit” and work on something new. Few things are worth holding your attention for a long period of time."]

    prompt = header + chosen_sections.join('')  + "\n\n Q: " + question + "\n A:"
    return prompt
end

def ask_question(prompt)
    return $client.completions(
        parameters: {
            prompt: prompt,
            temperature: 0.0,
            max_tokens: 300,
            model: COMPLETIONS_MODEL,
        }
    )
end

def ask(question, embedding)
    prompt = construct_query_promopt(embedding, question)
    answer = ask_question(prompt)
    p prompt
    return answer["choices"][0]["text"]
end

# $embedding = load_embedding_csv("./embeddings.csv")
# answer = ask("Is Gumroad Profitable?", $embedding)
# p answer

