- Feature Name: `store_screen_responses`
- Start Date: 2023-06-12
- RFC PR: [mbta/screens#1786](https://github.com/mbta/screens/pull/1786)
- Asana task: [Log and store all screen data responses](https://app.asana.com/0/1185117109217413/1204451311903806)
- Status: Proposed

# Summary / Motivation
[summary]: #summary

Problem statement:  The Screens team wants to be able to see visual renderings and data responses of past screen content in order to investigate rider reports of incorrect messages or do our own auditing of screen content.

Suggested approach: we want to store the json screen data responses in S3, as frequently as the screen content updates (every 15-30s). With the screen responses stored, we can run the json through frontend rendering and get (at least an MVP view) of past screens. We only need to store 90 days of data, at most. This json will only include content we display on screens and will never contain PII.

Note: At the moment, this will be a tool used mainly by the dev team, so we're not going to be too sophisticated with the retrieval and rendering process of the json right now. We did ideate about making a beautiful "screen time-travel view", but there are a few challenges with it that are explained in the #rationale-and-alternatives section. So we're going with an MVP user story here: an engineer needs to be able to see the data responses for historic screen content and be able to locally render the screen at that time. This method of local rendering is already doable, so data storage will be the focus of this work.

# Guide-level explanation
[guide-level-explanation]: #guide-level-explanation

For e-inks, this is every 30s. For other lcd screens, it could be as frequent as 15 or 20s.

Explain the proposal as if it was already implemented and you were teaching it to a new developer
that just joined the team. That generally means:

- Introducing new named concepts.
- Explaining the feature largely in terms of examples.
- Explaining how programmers should *think* about the feature, and how it should impact the way they
  work on this project. It should explain the impact as concretely as possible.
- If applicable, provide sample error messages, deprecation warnings, or migration guidance.
- If applicable, describe the differences between teaching this to senior developers and to junior
  developers.

We will store screen data responses in S3. This data response is a json blob that gets sent to the frontend renderer. Screen data requests happen at regular intervals for each screen type (and screens of the same type have intervals offset from one another). E-inks refresh every 30s, while lcd screens refresh every 15 or 20s. During each refresh, we already run a function that caches the alerts that are being displayed on a particular screen. So, with that logic we will also now push the screen data response to S3. 

There are a few attributes we want to make sure are included / added to the json blob to make future debugging more useful. Namely, we want to include alert ids and possibly trip ids for departures (since they are not necessarily needed for rendering the screen but would be helpful for later debugging.)

These responses will be stored by a screen ID prefix, and then within the screen ID by datetime. 

**What kind of load does this put on our S3 resources?**

A few important variables: we foresee wanting to retain no more than 90 days of history. And from trying out a couple example files, the blobs should be around 5-5.5KB in size. 

Splunk currently reports 90 active screen urls. (Some of the urls are reused on multiple units. For example, Ashmont has 2 Pre-Fare sets, and each set has 2 screen instances of our app url.) Splunk reports about 21.6k data requests an hour. If we catalog the json for each response at this scale, we'd have 518k files posted to S3 across 90 S3 prefixes. (Which is 46 million files stored over 90 days, or 244GB)

In the short term, we plan to add 200 new screens: about 180 e-ink and 20 miscellaneous screens by the end of the year. E-inks average 200 requests/hr while all other screens average around 240 requests/hr. This raises estimated data requests/hr to 46.4k.

In the long term, we may have a total of 1000 screens (countdown signs, 125 pre-fare pairs). This raises estimated data requests/hr to 214.4k. (463 million files over 90 days, 2.4TB)

# Drawbacks
[drawbacks]: #drawbacks

- Cost. How much does this go against our S3 budget? Preliminary budget calculation (with help from Paul S): this would be a 1% increase of our AWS bill. If this poses a problem, we can explore reducing retention, reducing duplicate posts for screens that share a url, and perhaps reducing frequency of posting altogether.
- Limited querying. If we needed more query fields, then there are DB options that would be better. But it doesn't seem we'll really be using these logs to do precise querying at this time. It's more for triaging particular screen issues.

# Rationale and alternatives
[rationale-and-alternatives]: #rationale-and-alternatives

Considered alternatives:
- Postgres with JSONB column
- S3 in Parquet file format
- Logging to Splunk using the json source_type

We stuck with the S3 solution rather than introduce a DB because:
- It should cover our requirements
- We already use S3 in the project stack
- The cost shouldn't be a problem (after discussing with some engineering leads)

As for using Parquet (recommended by the LAMP team) that would just help make the data more queryable, which we don't really need for our use case.

As for logging to Splunk, this was kind of a late-breaking idea, and I didn't immediately find anyone in CTD who has programmatically queried Splunk in this way before, so I just stuck with the S3 option as prime choice. (If the PR reviewers have other insight, this could be an interesting option.)

We also considered these alternatives to streamline the frontend rendering before deciding it was out of scope for this work:
- Store jpgs of the screen content
- Store html of the screens (tricky, because some screens have frontend paging that will not be represented in the html.)