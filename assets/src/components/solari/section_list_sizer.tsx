/**
 * SectionListSizer renders an invisible copy of the SectionList component in
 * order to determine the max number of departures that can be displayed without overflow.
 *
 * It then communicates the optimal row counts to its parent via the `onDoneSizing`
 * callback prop, to be used by the real SectionList.
 */

import React from "react";
import _ from "lodash";

import SectionList from "./section_list";

const totalRows = (sections) => {
  return sections.reduce((acc, section) => {
    if (section.paging && section.paging.is_enabled === true) {
      return acc + section.paging.visible_rows;
    } else {
      return acc + section.departures.length;
    }
  }, 0);
};

const allRoundings = (
  obj: Record<number, number>
): Record<number, number>[] => {
  return _.reduce(
    obj,
    (list, n, key) => {
      const floors = list.map((o) => ({ ...o, [key]: Math.floor(n) }));
      const ceils = list.map((o) => ({ ...o, [key]: Math.ceil(n) }));
      return [...floors, ...ceils];
    },
    [{}]
  );
};

const assignSectionSizes = (sections: object[], numRows: number): number[] => {
  // set the sizes for all empty sections to 1, to accomodate the "no departures" placeholder message
  const indexedAssignedEmpties = _.mapValues(
    _.pickBy({ ...sections }, (section) => section.departures.length === 0),
    () => 1
  );

  const indexedNonEmpties = _.pickBy(
    { ...sections },
    (section) => section.departures.length > 0
  );

  const indexedAssignedNonEmpties = assignSectionSizesHelper(
    indexedNonEmpties,
    numRows - _.size(indexedAssignedEmpties)
  );

  // merge the objects and convert back to an array
  return Array.from({
    ...indexedAssignedEmpties,
    ...indexedAssignedNonEmpties,
    length: _.size(indexedAssignedEmpties) + _.size(indexedAssignedNonEmpties),
  });
};

const assignSectionSizesHelper = (
  sections: Record<number, object>,
  numRows: number
): Record<number, number> => {
  const initialSizes = _.mapValues(sections, (section) => {
    if (section?.paging?.is_enabled) {
      return section.paging.visible_rows;
    } else {
      return section.departures.length;
    }
  });

  const initialRows = _.sum(Object.values(initialSizes));
  const scaledSizes = _.mapValues(
    initialSizes,
    (n) => (n * numRows) / initialRows
  );

  // Choose "best" rounding
  const allSizeCombinations = allRoundings(scaledSizes);
  const validSizeCombinations = allSizeCombinations.filter(
    (comb) => _.sum(Object.values(comb)) === numRows
  );
  const roundedSizes = _.minBy(validSizeCombinations, (comb) => {
    return _.sum(
      _.map(comb, (rounded, i) => Math.abs(rounded - scaledSizes[i]))
    );
  });

  return roundedSizes;
};

interface Props {
  sections: object[];
  sectionHeaders: string;
  currentTimeString: string;
  overhead: boolean;
  onDoneSizing: (sectionSizes: number[]) => void;
}

interface State {
  numRows: number;
  sectionSizes: number[];
}

class SectionListSizer extends React.Component<Props, State> {
  ref: React.RefObject<HTMLDivElement>;

  constructor(props: Props) {
    super(props);
    this.ref = React.createRef();
    this.MAX_DEPARTURES_HEIGHT = this.props.overhead ? 1464 : 1565;

    this.state = SectionListSizer.getInitialStateFromProps(props);
  }

  static getInitialStateFromProps(props: Props) {
    const initialRows = totalRows(props.sections);
    const initialSizes = assignSectionSizes(props.sections, initialRows);
    return { numRows: initialRows, sectionSizes: initialSizes };
  }

  componentDidMount() {
    if (this.shouldAdjustSectionSizes()) {
      this.adjustSectionSizes();
    } else {
      this.props.onDoneSizing(this.state.sectionSizes);
    }
  }

  // Prevent the component from entering a render loop when SectionListContainer updates its state
  shouldComponentUpdate(nextProps: Props, nextState: State) {
    return (
      this.props.currentTimeString !== nextProps.currentTimeString ||
      !this.stateEquals(nextState)
    );
  }

  componentDidUpdate(_props: Props, prevState: State) {
    const newStateFromProps = SectionListSizer.getInitialStateFromProps(
      this.props
    );

    if (this.stateEquals(prevState) && !this.stateEquals(newStateFromProps)) {
      this.setState(newStateFromProps);
    } else if (this.shouldAdjustSectionSizes()) {
      this.adjustSectionSizes();
    } else {
      this.props.onDoneSizing(this.state.sectionSizes);
    }
  }

  stateEquals(otherState: State) {
    const { numRows, sectionSizes } = this.state;
    return (
      numRows === otherState.numRows &&
      sectionSizes.length === otherState.sectionSizes.length &&
      sectionSizes.every((n, i) => n === otherState.sectionSizes[i])
    );
  }

  shouldAdjustSectionSizes() {
    if (this.ref.current != null) {
      const departuresHeight = this.ref.current.clientHeight;

      if (
        departuresHeight > this.MAX_DEPARTURES_HEIGHT &&
        this.state.numRows > 5
      ) {
        return true;
      }
    }
    return false;
  }

  adjustSectionSizes() {
    this.setState((prevState, prevProps) => {
      const newRows = prevState.numRows - 1;
      const newSizes = assignSectionSizes(prevProps.sections, newRows);
      return { numRows: newRows, sectionSizes: newSizes };
    });
  }

  render() {
    const {
      sections,
      sectionHeaders,
      currentTimeString,
      overhead,
    } = this.props;

    return (
      <SectionList
        sections={sections}
        sectionSizes={this.state.sectionSizes}
        sectionHeaders={sectionHeaders}
        currentTimeString={currentTimeString}
        overhead={overhead}
        isDummy
        ref={this.ref}
      />
    );
  }
}

export default SectionListSizer;
