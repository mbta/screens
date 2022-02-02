import React, { useContext, useEffect, useState } from "react";
import { LastFetchContext } from "Components/v2/screen_container";

const PersistentWrapper = ({WrappedComponent, ...data}) => {
  const lastFetch = useContext(LastFetchContext);

  const [visibleData, setVisibleData] = useState(data);
  const [isFinished, setIsFinished] = useState(false);
  const [renderKey, setRenderKey] = useState(0);

  const handleFinished = () => {
    setIsFinished(true);
  };

  useEffect(() => {
    if (isFinished) {
      setVisibleData(data);
      setRenderKey(n => n+1);
      setIsFinished(false);
    }
  }, [lastFetch]);

  return (
    <div>
      <BufferedData data={data.data} />
      <WrappedComponent {...visibleData} onFinish={handleFinished} key={renderKey} lastUpdate={lastFetch}/>
    </div>
  )
}

const makePersistent = (Component) => ({...data}) => <PersistentWrapper {...data} WrappedComponent={Component} />
export default makePersistent

const BufferedData = ({ data }) => {
  console.log('buffered data: ', data)
  return <div>Buffered Data ID: {data.id}</div>
}
