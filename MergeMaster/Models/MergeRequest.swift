//
//  MergeRequest.swift
//  MergeMaster
//
//  Created by Konshin on 18.12.16.
//  Copyright © 2016 Konshin. All rights reserved.
//

import Foundation

struct MergeRequest: Equatable {
  let id: Int
  let iid: Int
  let title: String
  let author: User
  let reviewers: [User]
  let assignees: [User]
  let webUrl: String
  let numberOfComments: Int
  let detailedMergeStatus: DetailedStatus
}

extension MergeRequest: Codable {

  private enum CodingKeys: String, CodingKey {
    case id, title, author, iid, reviewers, assignees
    case webUrl = "web_url"
    case numberOfComments = "user_notes_count"
    case detailedMergeStatus = "detailed_merge_status"
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(Int.self, forKey: .id)
    iid = try container.decode(Int.self, forKey: .iid)
    title = try container.decode(String.self, forKey: .title)
    author = try container.decode(User.self, forKey: .author)
    webUrl = try container.decode(String.self, forKey: .webUrl)
    numberOfComments = try container.decodeIfPresent(Int.self, forKey: .numberOfComments) ?? 0
    assignees = try container.decode([User].self, forKey: .assignees)
    reviewers = try container.decode([User].self, forKey: .reviewers)
    detailedMergeStatus = try container.decodeIfPresent(DetailedStatus.self, forKey: .detailedMergeStatus) ?? .unknown
  }
}

extension MergeRequest {
  enum DetailedStatus: String, Codable {
    case approvalsSyncing = "approvals_syncing"
    case checking
    case ciMustPass = "ci_must_pass"
    case ciStillRunning = "ci_still_running"
    case commitsStatus = "commits_status"
    case conflict
    case discussionsNotResolved = "discussions_not_resolved"
    case draft_status = "draft_status"
    case jiraAssociationMissing = "jira_association_missing"
    case mergeable
    case mergeRequestBlocked = "merge_request_blocked"
    case mergeTime = "merge_time"
    case needRebase = "need_rebase"
    case notApproved = "not_approved"
    case notOpen = "not_open"
    case preparing
    case requestedChanges = "requested_changes"
    case securityPolicyEvaluation = "security_policy_evaluation"
    case securityPolicyViolations = "security_policy_violations"
    case statusChecksMustPass = "status_checks_must_pass"
    case unchecked = "unchecked"
    case lockedPaths = "locked_paths"
    case lockedLfsFiles = "locked_lfs_files"
    case unknown
  }
}

extension MergeRequest.DetailedStatus {
  enum Category {
    case userActionRequired
    case readyToMerge
    case waitingForResultOfSth
  }

  init(from decoder: any Decoder) throws {
    do {
      let container = try decoder.singleValueContainer()
      let stringValue = try container.decode(String.self)
      self = MergeRequest.DetailedStatus(rawValue: stringValue) ?? .unknown
    } catch {
      self = .unknown
    }
  }

  var title: String {
    switch self {
    case .approvalsSyncing:
      return "Approvals syncing"
    case .checking:
      return "Checking"
    case .ciMustPass:
      return "CI must pass"
    case .ciStillRunning:
      return "CI still running"
    case .commitsStatus:
      return "Commits status"
    case .conflict:
      return "Conflict"
    case .discussionsNotResolved:
      return "Discussions not resolved"
    case .draft_status:
      return "Draft status"
    case .jiraAssociationMissing:
      return "Jira association missing"
    case .mergeable:
      return "Mergeable"
    case .mergeRequestBlocked:
      return "Merge request blocked"
    case .mergeTime:
      return "Merge time"
    case .needRebase:
      return "Need rebase"
    case .notApproved:
      return "Not approved"
    case .notOpen:
      return "Not open"
    case .preparing:
      return "Preparing"
    case .requestedChanges:
      return "Requested changes"
    case .securityPolicyEvaluation:
      return "Security policy evaluation"
    case .securityPolicyViolations:
      return "Security policy violations"
    case .statusChecksMustPass:
      return "Status checks must pass"
    case .unchecked:
      return "Unchecked"
    case .lockedPaths:
      return "Locked paths"
    case .lockedLfsFiles:
      return "Locked LFS files"
    case .unknown:
      return "Unknown"
    }
  }
  
  /// Markdown string
  var description: String? {
    switch self {
    case .approvalsSyncing:
      return "The merge request’s approvals are syncing."
    case .checking:
      return "Git is testing if a valid merge is possible."
    case .ciMustPass:
      return "A CI/CD pipeline must succeed before merge."
    case .ciStillRunning:
      return "A CI/CD pipeline is still running."
    case .commitsStatus:
      return "Source branch should exist, and contain commits."
    case .conflict:
      return "Conflicts exist between the source and target branches."
    case .discussionsNotResolved:
      return "All discussions must be resolved before merge."
    case .draft_status:
      return "Can’t merge because the merge request is a draft."
    case .jiraAssociationMissing:
      return "The title or description must reference a Jira issue. To configure, see [Require associated Jira issue for merge requests to be merged.](https://docs.gitlab.com/ee/integration/jira/issues.html#require-associated-jira-issue-for-merge-requests-to-be-merged)"
    case .mergeable:
      return "The branch can merge cleanly into the target branch."
    case .mergeRequestBlocked:
      return "Blocked by another merge request."
    case .mergeTime:
      return "May not be merged until after the specified time."
    case .needRebase:
      return "The merge request must be rebased."
    case .notApproved:
      return "Approval is required before merge."
    case .notOpen:
      return "The merge request must be open before merge."
    case .preparing:
      return "Merge request diff is being created."
    case .requestedChanges:
      return "The merge request has reviewers who have requested changes."
    case .securityPolicyEvaluation:
      return "All security policies must be evaluated. Requires the `policy_mergability_check` feature flag to be enabled."
    case .securityPolicyViolations:
      return "All security policies must be satisfied. Requires the `policy_mergability_check` feature flag to be enabled."
    case .statusChecksMustPass:
      return "All status checks must pass before merge."
    case .unchecked:
      return "Git has not yet tested if a valid merge is possible."
    case .lockedPaths:
      return "Paths locked by other users must be unlocked before merging to default branch."
    case .lockedLfsFiles:
      return "LFS files locked by other users must be unlocked before merge."
    case .unknown:
      return nil
    }
  }

  var category: Category {
    switch self {
    case .approvalsSyncing, .checking, .ciMustPass, .ciStillRunning, .draft_status, .mergeRequestBlocked, .mergeTime, .notApproved, .notOpen, .preparing, .unknown, .unchecked, .statusChecksMustPass:
      return .waitingForResultOfSth
    case .conflict, .discussionsNotResolved, .commitsStatus, .jiraAssociationMissing, .needRebase, .requestedChanges, .securityPolicyEvaluation, .securityPolicyViolations, .lockedPaths, .lockedLfsFiles:
      return .userActionRequired
    case .mergeable:
      return .readyToMerge
    }
  }
}
