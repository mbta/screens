import { imagePath } from "Util/utils";
import LinkFooter from "Components/eink/link_footer";

const FareInfo = ({ modeIcon, modeText, modeCost }) => {
  return (
    <div className="fare-info">
      <div className="fare-info__icon">
        <img className="fare-info__icon-image" src={imagePath(modeIcon)} />
      </div>
      <div className="fare-info__message">
        <div className="fare-info__message-header">{modeText} One-Way</div>
        <div className="fare-info__message-body">
          CharlieCard, CharlieTicket, contactless payment, or cash accepted on
          board
        </div>
      </div>
      <div className="fare-info__cost">{modeCost}</div>
    </div>
  );
};

const FareInfoFooter = ({
  mode_icon: modeIcon,
  mode_text: modeText,
  mode_cost: modeCost,
  text,
  url,
}) => {
  return (
    <>
      <FareInfo modeIcon={modeIcon} modeText={modeText} modeCost={modeCost} />
      <LinkFooter text={text} url={url} />
    </>
  );
};

export default FareInfoFooter;
