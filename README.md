

# Overview

This repo contains [Scrumdinger app](https://developer.apple.com/tutorials/app-dev-training/getting-started) from Apple's tutorial, rewritten in uni-directional architecture [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture).

## Motivation

I created this repo to learn & explore the [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) that was made by [Brandon Williams](https://www.twitter.com/mbrandonw) and [Stephen Celis](https://www.twitter.com/stephencelis).

Instead of starting with greenfield Xcode project I decided to pickup the final version of Scrumdinger app, that seemed to me to be just at the right size for this exercise. I took the official Apple tutorial prior to starting migrating it to CA, prior familiarity with the Scrumdinger project was thus considered a plus.
I decided to open-source my findings to help others and me to improve the understanding of the Composable Architecture.

_**Note:**_

This project is in highly experimental/prototyping stage and is not meant for production use.

In terms of functionality/features, this project aims to be 1:1 consistent with the of the Apple's Scrumdinger app, but don't expect me to not break the things along the way :)

### Scrumdinger app

Scrumdinger app gives you possibility to maintain your scrum meetings.
Scrum meetings can be added, edited, started & recorded.

Every scrum meeting has following attributes:
* name
* length
* color
* list of attendees
* history of transcripts from previous meetings

Below you can find the basic user flow of the Scrumdinger app.
![Flow](./resources/Scrumdinger.png)

### Learnings and Explorations

In this section I'll roughly talk about my approaches that I took when rewriting the Scrumdinger app's vanilla SwiftUI into Composable Architecture.

I won't talk about uni-directional architecture, its pros or cons here. There's already quantum of articles that discuss this topic, and on top of that, I'll rather go straight to the point.

By looking at the app's view hierarchy I naturally started to rewrite the views from the bottom up.

_Note: There are few views/components left untouched, since applying the CA to them wouldn't add much value_
![Graph](./resources/graph.png)

Thanks to SwiftUI previews this gave me the opportunity to iteratively rewrite views & the state management behind them without declaring the world war III against the Swift compiler.

### Simplest case for State, Actions, Environment, Reducer and Store

The pattern that I repeated several times in this project was to actually declare a dedicated `State`, `Actions`, `Environment` and `Reducer` for each view in 1:1 ratio.

How did it look like in the simplest case? Here are few steps that I followed when turning the `MeetingFooterView` into CA.

![Before](./resources/view-state-before.png)

1. First of all, add `ComposableArchitecture` package to the project.
2. Import CA in the source file `import ComposableArchitecture`.
3. Identify all the properties that keep the view's state and move them to standalone `State` struct(or enum) that conforms to `Equatable` protocol.

    3.1. Turn all properties to access level of your store - eg from `private` to `internal`.

![After](./resources/view-state-after.png)

_Note: Comment out all the lines of code that don't compile at this moment. You'll uncomment them once you're ready!_

4. Identify actions in your view and model them via equatable `enum`. Actions doesn't necessarily need to be user-initiated.
![Action](./resources/view-action.png)

5. Declare corresponding `environment` struct if needed. In the case, I skipped the declaration of the environment, as it wasnt needed.

6. Maybe I did something wrong, but I found out that I didn't need to declare `reducer` for this view.

7. Declare and use the `store` in the SwiftUI view.

    7.1. Declare the `store` property, that contains two associated values. Your newly created `MeetingFooterState` and `MeetingFooterAction`.

    7.2. Use `viewStore` in the `body` of your view by calling following API - ```WithViewStore(store) { viewStore in ... }```

    7.3. Access the `state` through the passed in `viewStore` parameter.

    7.4. Send the `action` to the store by using the `viewStore.send(MeetingFooterAction)` API.
![Store](./resources/view-store.png)

8. Update your preview provider to conform to the new API. Tadaaa
![Preview](./resources/view-preview.png)



## TBC..



## Licensing
Please look at [License](https://github.com/bielikb/scrumdinger/blob/main/LICENSE/LICENSE.txt) for more details.
