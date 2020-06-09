import React from "react";
import _ from "lodash";

import { PagedSection, Section } from "Components/solari/section";

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

interface SectionListProps {
  sections: object[];
  sectionHeaders: string;
  currentTimeString: string;
}

interface SectionListState {
  numRows: number;
  sectionSizes: number[];
}

const MAX_DEPARTURES_HEIGHT = 1565;

class SectionList extends React.Component<SectionListProps, SectionListState> {
  ref: React.RefObject<HTMLDivElement>;

  constructor(props: SectionListProps) {
    super(props);
    this.ref = React.createRef();

    this.state = SectionList.getInitialStateFromProps(props);
  }

  static getInitialStateFromProps(props: SectionListProps) {
    const initialRows = totalRows(props.sections);
    const initialSizes = assignSectionSizes(props.sections, initialRows);
    return { numRows: initialRows, sectionSizes: initialSizes };
  }

  componentDidMount() {
    this.maybeAdjustSectionSizes();
  }

  componentDidUpdate(_props: SectionListProps, prevState: SectionListState) {
    const newStateFromProps = SectionList.getInitialStateFromProps(this.props);

    if (this.stateEquals(prevState) && !this.stateEquals(newStateFromProps)) {
      this.setState(newStateFromProps);
    } else {
      this.maybeAdjustSectionSizes();
    }
  }

  stateEquals(otherState: SectionListState) {
    const { numRows, sectionSizes } = this.state;
    return (
      numRows === otherState.numRows &&
      sectionSizes.length === otherState.sectionSizes.length &&
      sectionSizes.every((n, i) => n === otherState.sectionSizes[i])
    );
  }

  maybeAdjustSectionSizes() {
    if (this.ref.current != null) {
      const departuresHeight = this.ref.current.clientHeight;

      if (departuresHeight > MAX_DEPARTURES_HEIGHT && this.state.numRows > 5) {
        this.setState((prevState, prevProps) => {
          const newRows = prevState.numRows - 1;
          const newSizes = assignSectionSizes(prevProps.sections, newRows);
          return { numRows: newRows, sectionSizes: newSizes };
        });
      }
    }
  }

  render() {
    const { sections, sectionHeaders, currentTimeString } = this.props;

    return (
      <div className="section-list" ref={this.ref}>
        {sections.map((section, i) => {
          if (section.paging && section.paging.is_enabled === true) {
            return (
              <PagedSection
                {...section}
                numRows={this.state.sectionSizes[i]}
                sectionHeaders={sectionHeaders}
                currentTimeString={currentTimeString}
                key={
                  section.name + this.state.sectionSizes[i] + currentTimeString
                }
              />
            );
          } else {
            return (
              <Section
                {...section}
                numRows={this.state.sectionSizes[i]}
                sectionHeaders={sectionHeaders}
                currentTimeString={currentTimeString}
                key={
                  section.name + this.state.sectionSizes[i] + currentTimeString
                }
              />
            );
          }
        })}
      </div>
    );
  }
}

export default SectionList;
