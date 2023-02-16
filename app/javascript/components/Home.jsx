import React, { useState } from "react";

const OutputState = 'LOADING' | 'ANSWER' | 'NONE'   // this can be used to typecheck answerState if we enable typescript 

function PrimaryButton(props) {
  return <button
    onClick={props.onClick}
    className="bg-blue-500 hover:bg-blue-700 text-white py-2 px-4 rounded">
    {props.text}
  </button>
}

export default () => {
  const [question, setQuestion] = useState("What is The Minimalist Entrepreneur about?")
  const [answer, setAnswer] = useState(null)
  const [answerState, setAnswerState] = useState('NONE')

  React.useEffect(() => {
    fetch('/home/load', {
      method: 'GET',
    })
  }, [])


  const answerContent = () => {
    switch (answerState) {
      case 'NONE':
        return <PrimaryButton text="Ask a Question" onClick={handleSubmit} />
      case 'LOADING':
        return <>
          <p className="font-bold">Answer: </p> <br />
          <div className="spinner-border animate-spin inline-block w-8 h-8 border-4 rounded-full"></div>
        </>
      case 'ANSWER':
        return <>
          <p className="font-bold">Answer: </p> <br />
          <p className="font-mono py-1">{answer}</p> <br />
          <PrimaryButton className="" text="Ask another Question" onClick={handleAnotherQ} />
        </>
    }
  }

  const handleAnotherQ = () => {
    var textarea = document.getElementById("questionInput");
    textarea.focus()
    textarea.select()
    setAnswerState('NONE')
  }

  const token = document.querySelector('meta[name="csrf-token"]').content
  const handleSubmit = async (event) => {
    event.preventDefault();
    setAnswerState('LOADING')
    let body = JSON.stringify({ question })
    const response = await fetch('/home/ask', {
      method: 'POST',
      body: body,
      headers: {
        "X-CSRF-Token": token,
        'Content-Type': 'application/json'
      },
    })
    const data = await response.json()
    setAnswer(data.answer)
    setAnswerState('ANSWER')
  }

  return (
    <div className="flex items-center justify-center flex-col font-sans">
      <div className="w-1/6 p-6 m-4">
        <img src="https://m.media-amazon.com/images/I/711KXUuHfbL._AC_UF1000,1000_QL80_.jpg" alt="..."
          className="shadow rounded max-w-full h-auto align-middle border-2" />
      </div>
      <h1 className="p-4 text-2xl font-bold">Ask My Book</h1>
      <div className="w-1/3 flex items-center justify-center flex-col ml-auto mr-auto">
        <textarea rows="3"
          id="questionInput"
          value={question}
          onChange={(e) => setQuestion(e.target.value)}
          className="font-mono block m-4 p-2.5 w-full text-md text-black bg-gray-50 rounded-lg border border-black focus:text-sky-500 focus:border-blue-500"
        />
        <div className="flex flex-col items-center justify-center">
          {answerContent()}
        </div>
      </div>
    </div>
  )
}
