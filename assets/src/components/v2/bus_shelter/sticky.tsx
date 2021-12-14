import useInterval from "Hooks/use_interval";
import React, { useEffect, useState } from "react";

const dummyData = [
  { id: 1, data: [1, 2, 3] },
  { id: 2, data: [1, 2] },
  { id: 3, data: [1, 2, 3, 4] },
  { id: 4, data: [1] },
]

const Sticky = () => {
  const [bufferedData, setBufferedData] = useState({ id: null, data: []})
  const [visibleData, setVisibleData] = useState({ id: null, data: []})
  const [newRotation, setNewRotation] = useState(true)

  // mimic fetching background data periodically
  useInterval(() => {
    const index = Math.floor(Math.random() * 4)
    setBufferedData(dummyData[index])
    console.log('got new data from backend')
  }, 10000)

  useEffect(() => {
    if (newRotation) {
      setVisibleData(bufferedData)
      setNewRotation(false)
    }

  }, [newRotation])

  return (
    <div>
      <BufferedData data={bufferedData} />
      <VisibleData data={visibleData} onFinish={() => setNewRotation(true)} />
    </div>
  )
}

export default Sticky

const BufferedData = ({ data }) => (<div>Buffered Data: {data.id}</div>)

const VisibleData = ({ data, onFinish }) => {
  const [currentPage, setCurrentPage] = useState(0)
  const maxPages = data.data.length

  useInterval(() => {
    console.log('page switch')
    // data hasn't been loaded yet, can be handled better in parent component by not rendering w/ empty data set
    if (data.data.length === 0) { 
      setCurrentPage(0) 
      onFinish()
    // at last page?
    } else if (currentPage === maxPages - 1) {
      onFinish()
      setCurrentPage(0)
    } else {
      setCurrentPage(currentPage + 1)
    }
  }, 2000)

  return (<div>Visible Data: {data.id} currentPage: {currentPage} maxPages: {maxPages} data: {data.data[currentPage]}</div>)
}