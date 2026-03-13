-- =============================================================================
-- B1Stack PostgreSQL DDL — generated from Drizzle PG schema definitions
-- =============================================================================
-- Each module uses its own PG schema (membership, attendance, content, giving,
-- messaging, doing). Tables use CREATE TABLE IF NOT EXISTS for idempotency.
-- Indexes and enum types are omitted (handled separately).
-- =============================================================================

-- =============================================================================
-- MODULE: membership
-- =============================================================================
SET search_path TO membership, public;

CREATE TABLE IF NOT EXISTS "accessLogs" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "userId" char(11),
  "churchId" char(11),
  "appName" varchar(45),
  "loginTime" timestamp
);

CREATE TABLE IF NOT EXISTS "answers" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "formSubmissionId" char(11),
  "questionId" char(11),
  "value" varchar(4000)
);

CREATE TABLE IF NOT EXISTS "auditLogs" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11) NOT NULL,
  "userId" char(11),
  "category" varchar(50) NOT NULL,
  "action" varchar(100) NOT NULL,
  "entityType" varchar(100),
  "entityId" char(11),
  "details" text,
  "ipAddress" varchar(45),
  "created" timestamp NOT NULL
);

CREATE TABLE IF NOT EXISTS "churches" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "name" varchar(255),
  "subDomain" varchar(45),
  "registrationDate" timestamp,
  "address1" varchar(255),
  "address2" varchar(255),
  "city" varchar(255),
  "state" varchar(45),
  "zip" varchar(45),
  "country" varchar(45),
  "archivedDate" timestamp,
  "latitude" real,
  "longitude" real
);

CREATE TABLE IF NOT EXISTS "clientErrors" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "application" varchar(45),
  "errorTime" timestamp,
  "userId" char(11),
  "churchId" char(11),
  "originUrl" varchar(255),
  "errorType" varchar(45),
  "message" varchar(255),
  "details" text
);

CREATE TABLE IF NOT EXISTS "domains" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "domainName" varchar(255),
  "lastChecked" timestamp,
  "isStale" smallint DEFAULT 0
);

CREATE TABLE IF NOT EXISTS "forms" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "name" varchar(255),
  "contentType" varchar(50),
  "createdTime" timestamp,
  "modifiedTime" timestamp,
  "accessStartTime" timestamp,
  "accessEndTime" timestamp,
  "restricted" boolean,
  "archived" boolean,
  "removed" boolean,
  "thankYouMessage" text
);

CREATE TABLE IF NOT EXISTS "formSubmissions" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "formId" char(11),
  "contentType" varchar(50),
  "contentId" char(11),
  "submissionDate" timestamp,
  "submittedBy" char(11),
  "revisionDate" timestamp,
  "revisedBy" char(11)
);

CREATE TABLE IF NOT EXISTS "groupMembers" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "groupId" char(11),
  "personId" char(11),
  "joinDate" timestamp,
  "leader" boolean
);

CREATE TABLE IF NOT EXISTS "groups" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "categoryName" varchar(50),
  "name" varchar(50),
  "trackAttendance" boolean,
  "parentPickup" boolean,
  "printNametag" boolean,
  "about" text,
  "photoUrl" varchar(255),
  "removed" boolean,
  "tags" varchar(45),
  "meetingTime" varchar(45),
  "meetingLocation" varchar(45),
  "labels" varchar(500),
  "slug" varchar(45)
);

CREATE TABLE IF NOT EXISTS "households" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "name" varchar(50)
);

CREATE TABLE IF NOT EXISTS "memberPermissions" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "memberId" char(11),
  "contentType" varchar(45),
  "contentId" char(11),
  "action" varchar(45),
  "emailNotification" boolean
);

CREATE TABLE IF NOT EXISTS "notes" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "contentType" varchar(50),
  "contentId" char(11),
  "noteType" varchar(50),
  "addedBy" char(11),
  "createdAt" timestamp,
  "contents" text,
  "updatedAt" timestamp
);

CREATE TABLE IF NOT EXISTS "oAuthClients" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "name" varchar(45),
  "clientId" varchar(45),
  "clientSecret" varchar(45),
  "redirectUris" varchar(255),
  "scopes" varchar(255),
  "createdAt" timestamp
);

CREATE TABLE IF NOT EXISTS "oAuthCodes" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "userChurchId" char(11),
  "clientId" char(11),
  "code" varchar(45),
  "redirectUri" varchar(255),
  "scopes" varchar(255),
  "expiresAt" timestamp,
  "createdAt" timestamp
);

CREATE TABLE IF NOT EXISTS "oAuthDeviceCodes" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "deviceCode" varchar(64) NOT NULL,
  "userCode" varchar(16) NOT NULL,
  "clientId" varchar(45) NOT NULL,
  "scopes" varchar(255),
  "expiresAt" timestamp NOT NULL,
  "pollInterval" integer DEFAULT 5,
  "status" varchar(20) DEFAULT 'pending',
  "approvedByUserId" char(11),
  "userChurchId" char(11),
  "churchId" char(11),
  "createdAt" timestamp
);

CREATE TABLE IF NOT EXISTS "oAuthRelaySessions" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "sessionCode" varchar(16) NOT NULL,
  "provider" varchar(45) NOT NULL,
  "authCode" varchar(512),
  "redirectUri" varchar(512) NOT NULL,
  "status" varchar(20) DEFAULT 'pending',
  "expiresAt" timestamp NOT NULL,
  "createdAt" timestamp
);

CREATE TABLE IF NOT EXISTS "oAuthTokens" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "clientId" char(11),
  "userChurchId" char(11),
  "accessToken" varchar(1000),
  "refreshToken" varchar(45),
  "scopes" varchar(45),
  "expiresAt" timestamp,
  "createdAt" timestamp
);

CREATE TABLE IF NOT EXISTS "people" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "userId" char(11),
  "displayName" varchar(100),
  "firstName" varchar(50),
  "middleName" varchar(50),
  "lastName" varchar(50),
  "nickName" varchar(50),
  "prefix" varchar(10),
  "suffix" varchar(10),
  "birthDate" timestamp,
  "gender" varchar(11),
  "maritalStatus" varchar(10),
  "anniversary" timestamp,
  "membershipStatus" varchar(50),
  "homePhone" varchar(21),
  "mobilePhone" varchar(21),
  "workPhone" varchar(21),
  "email" varchar(100),
  "address1" varchar(50),
  "address2" varchar(50),
  "city" varchar(30),
  "state" varchar(10),
  "zip" varchar(10),
  "photoUpdated" timestamp,
  "householdId" char(11),
  "householdRole" varchar(10),
  "removed" boolean,
  "conversationId" char(11),
  "optedOut" boolean,
  "nametagNotes" varchar(20),
  "donorNumber" varchar(20)
);

CREATE TABLE IF NOT EXISTS "questions" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "formId" char(11),
  "parentId" char(11),
  "title" varchar(255),
  "description" varchar(255),
  "fieldType" varchar(50),
  "placeholder" varchar(50),
  "sort" integer,
  "choices" text,
  "removed" boolean,
  "required" boolean
);

CREATE TABLE IF NOT EXISTS "roleMembers" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "roleId" char(11),
  "userId" char(11),
  "dateAdded" timestamp,
  "addedBy" char(11)
);

CREATE TABLE IF NOT EXISTS "rolePermissions" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "roleId" char(11),
  "apiName" varchar(45),
  "contentType" varchar(45),
  "contentId" char(11),
  "action" varchar(45)
);

CREATE TABLE IF NOT EXISTS "roles" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "name" varchar(255)
);

CREATE TABLE IF NOT EXISTS "settings" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "userId" char(11),
  "keyName" varchar(255),
  "value" text,
  "public" boolean
);

CREATE TABLE IF NOT EXISTS "usageTrends" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "year" integer,
  "week" integer,
  "b1Users" integer,
  "b1Churches" integer,
  "b1Devices" integer,
  "chumsUsers" integer,
  "chumsChurches" integer,
  "lessonsUsers" integer,
  "lessonsChurches" integer,
  "lessonsDevices" integer,
  "freeShowDevices" integer
);

CREATE TABLE IF NOT EXISTS "userChurches" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "userId" char(11),
  "churchId" char(11),
  "personId" char(11),
  "lastAccessed" timestamp
);

CREATE TABLE IF NOT EXISTS "users" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "email" varchar(191),
  "password" varchar(255),
  "authGuid" varchar(255),
  "displayName" varchar(255),
  "registrationDate" timestamp,
  "lastLogin" timestamp,
  "firstName" varchar(45),
  "lastName" varchar(45)
);

CREATE TABLE IF NOT EXISTS "visibilityPreferences" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "personId" char(11),
  "address" varchar(50),
  "phoneNumber" varchar(50),
  "email" varchar(50)
);


-- =============================================================================
-- MODULE: attendance
-- =============================================================================
SET search_path TO attendance, public;

CREATE TABLE IF NOT EXISTS "campuses" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "name" varchar(255),
  "address1" varchar(50),
  "address2" varchar(50),
  "city" varchar(50),
  "state" varchar(10),
  "zip" varchar(10),
  "removed" boolean
);

CREATE TABLE IF NOT EXISTS "services" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "campusId" char(11),
  "name" varchar(50),
  "removed" boolean
);

CREATE TABLE IF NOT EXISTS "serviceTimes" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "serviceId" char(11),
  "name" varchar(50),
  "removed" boolean
);

CREATE TABLE IF NOT EXISTS "sessions" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "groupId" char(11),
  "serviceTimeId" char(11),
  "sessionDate" timestamp
);

CREATE TABLE IF NOT EXISTS "visits" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "personId" char(11),
  "serviceId" char(11),
  "groupId" char(11),
  "visitDate" timestamp,
  "checkinTime" timestamp,
  "addedBy" char(11)
);

CREATE TABLE IF NOT EXISTS "visitSessions" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "visitId" char(11),
  "sessionId" char(11)
);

CREATE TABLE IF NOT EXISTS "groupServiceTimes" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "groupId" char(11),
  "serviceTimeId" char(11)
);

CREATE TABLE IF NOT EXISTS "settings" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "keyName" varchar(255),
  "value" varchar(255)
);


-- =============================================================================
-- MODULE: content
-- =============================================================================
SET search_path TO content, public;

CREATE TABLE IF NOT EXISTS "arrangementKeys" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "arrangementId" char(11),
  "keySignature" varchar(10),
  "shortDescription" varchar(45)
);

CREATE TABLE IF NOT EXISTS "arrangements" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "songId" char(11),
  "songDetailId" char(11),
  "name" varchar(45),
  "lyrics" text,
  "freeShowId" varchar(45)
);

CREATE TABLE IF NOT EXISTS "bibleBooks" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "translationKey" varchar(45),
  "keyName" varchar(45),
  "abbreviation" varchar(45),
  "name" varchar(45),
  "sort" integer
);

CREATE TABLE IF NOT EXISTS "bibleChapters" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "translationKey" varchar(45),
  "bookKey" varchar(45),
  "keyName" varchar(45),
  "number" integer
);

CREATE TABLE IF NOT EXISTS "bibleLookups" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "translationKey" varchar(45),
  "lookupTime" timestamp,
  "ipAddress" varchar(45),
  "startVerseKey" varchar(15),
  "endVerseKey" varchar(15)
);

CREATE TABLE IF NOT EXISTS "bibleTranslations" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "abbreviation" varchar(10),
  "name" varchar(255),
  "nameLocal" varchar(255),
  "description" varchar(1000),
  "source" varchar(45),
  "sourceKey" varchar(45),
  "language" varchar(45),
  "countries" varchar(255),
  "copyright" varchar(1000),
  "attributionRequired" boolean,
  "attributionString" varchar(1000)
);

CREATE TABLE IF NOT EXISTS "bibleVerses" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "translationKey" varchar(45),
  "chapterKey" varchar(45),
  "keyName" varchar(45),
  "number" integer
);

CREATE TABLE IF NOT EXISTS "bibleVerseTexts" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "translationKey" varchar(45),
  "verseKey" varchar(45),
  "bookKey" varchar(45),
  "chapterNumber" integer,
  "verseNumber" integer,
  "content" varchar(1000),
  "newParagraph" boolean
);

CREATE TABLE IF NOT EXISTS "blocks" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "blockType" varchar(45),
  "name" varchar(45)
);

CREATE TABLE IF NOT EXISTS "curatedCalendars" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "name" varchar(45)
);

CREATE TABLE IF NOT EXISTS "curatedEvents" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "curatedCalendarId" char(11),
  "groupId" char(11),
  "eventId" char(11)
);

CREATE TABLE IF NOT EXISTS "elements" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "sectionId" char(11),
  "blockId" char(11),
  "elementType" varchar(45),
  "sort" real,
  "parentId" char(11),
  "answersJSON" text,
  "stylesJSON" text,
  "animationsJSON" text
);

CREATE TABLE IF NOT EXISTS "eventExceptions" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "eventId" char(11),
  "exceptionDate" timestamp,
  "recurrenceDate" timestamp
);

CREATE TABLE IF NOT EXISTS "events" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "groupId" char(11),
  "allDay" boolean,
  "start" timestamp,
  "end" timestamp,
  "title" varchar(255),
  "description" text,
  "visibility" varchar(45),
  "recurrenceRule" varchar(255),
  "registrationEnabled" boolean,
  "capacity" integer,
  "registrationOpenDate" timestamp,
  "registrationCloseDate" timestamp,
  "tags" varchar(500),
  "formId" char(11)
);

CREATE TABLE IF NOT EXISTS "files" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "contentType" varchar(45),
  "contentId" char(11),
  "fileName" varchar(255),
  "contentPath" varchar(1024),
  "fileType" varchar(45),
  "size" integer,
  "dateModified" timestamp
);

CREATE TABLE IF NOT EXISTS "globalStyles" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "fonts" text,
  "palette" text,
  "typography" text,
  "spacing" text,
  "borderRadius" text,
  "customCss" text,
  "customJS" text
);

CREATE TABLE IF NOT EXISTS "links" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "category" varchar(45),
  "url" varchar(255),
  "linkType" varchar(45),
  "linkData" varchar(255),
  "icon" varchar(45),
  "text" varchar(255),
  "sort" real,
  "photo" varchar(255),
  "parentId" char(11),
  "visibility" varchar(45) DEFAULT 'everyone',
  "groupIds" text
);

CREATE TABLE IF NOT EXISTS "pageHistory" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "pageId" char(11),
  "blockId" char(11),
  "snapshotJSON" text,
  "description" varchar(200),
  "userId" char(11),
  "createdDate" timestamp
);

CREATE TABLE IF NOT EXISTS "pages" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "url" varchar(255),
  "title" varchar(255),
  "layout" varchar(45)
);

CREATE TABLE IF NOT EXISTS "playlists" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "title" varchar(255),
  "description" text,
  "publishDate" timestamp,
  "thumbnail" varchar(1024)
);

CREATE TABLE IF NOT EXISTS "registrationMembers" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11) NOT NULL,
  "registrationId" char(11) NOT NULL,
  "personId" char(11),
  "firstName" varchar(100),
  "lastName" varchar(100)
);

CREATE TABLE IF NOT EXISTS "registrations" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11) NOT NULL,
  "eventId" char(11) NOT NULL,
  "personId" char(11),
  "householdId" char(11),
  "status" varchar(20) DEFAULT 'pending',
  "formSubmissionId" char(11),
  "notes" text,
  "registeredDate" timestamp,
  "cancelledDate" timestamp
);

CREATE TABLE IF NOT EXISTS "sections" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "pageId" char(11),
  "blockId" char(11),
  "zone" varchar(45),
  "background" varchar(255),
  "textColor" varchar(45),
  "headingColor" varchar(45),
  "linkColor" varchar(45),
  "sort" real,
  "targetBlockId" char(11),
  "answersJSON" text,
  "stylesJSON" text,
  "animationsJSON" text
);

CREATE TABLE IF NOT EXISTS "sermons" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "playlistId" char(11),
  "videoType" varchar(45),
  "videoData" varchar(255),
  "videoUrl" varchar(1024),
  "title" varchar(255),
  "description" text,
  "publishDate" timestamp,
  "thumbnail" varchar(1024),
  "duration" integer,
  "permanentUrl" boolean
);

CREATE TABLE IF NOT EXISTS "settings" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "userId" char(11),
  "keyName" varchar(255),
  "value" text,
  "public" boolean
);

CREATE TABLE IF NOT EXISTS "songDetailLinks" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "songDetailId" char(11),
  "service" varchar(45),
  "serviceKey" varchar(255),
  "url" varchar(255)
);

CREATE TABLE IF NOT EXISTS "songDetails" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "praiseChartsId" varchar(45),
  "musicBrainzId" varchar(45),
  "title" varchar(45),
  "artist" varchar(45),
  "album" varchar(45),
  "language" varchar(5),
  "thumbnail" varchar(255),
  "releaseDate" date,
  "bpm" integer,
  "keySignature" varchar(5),
  "seconds" integer,
  "meter" varchar(10),
  "tones" varchar(45)
);

CREATE TABLE IF NOT EXISTS "songs" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "name" varchar(45),
  "dateAdded" date
);

CREATE TABLE IF NOT EXISTS "streamingServices" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "serviceTime" timestamp,
  "earlyStart" integer,
  "chatBefore" integer,
  "chatAfter" integer,
  "provider" varchar(45),
  "providerKey" varchar(255),
  "videoUrl" varchar(5000),
  "timezoneOffset" integer,
  "recurring" boolean,
  "label" varchar(255),
  "sermonId" char(11)
);


-- =============================================================================
-- MODULE: giving
-- =============================================================================
SET search_path TO giving, public;

CREATE TABLE IF NOT EXISTS "customers" (
  "id" varchar(255) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "personId" char(11),
  "provider" varchar(50),
  "metadata" json
);

CREATE TABLE IF NOT EXISTS "donationBatches" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "name" varchar(50),
  "batchDate" timestamp
);

CREATE TABLE IF NOT EXISTS "donations" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "batchId" char(11),
  "personId" char(11),
  "donationDate" timestamp,
  "amount" double precision,
  "currency" varchar(10),
  "method" varchar(50),
  "methodDetails" varchar(255),
  "notes" text,
  "entryTime" timestamp,
  "status" varchar(20) DEFAULT 'complete',
  "transactionId" varchar(255)
);

CREATE TABLE IF NOT EXISTS "eventLogs" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "customerId" varchar(255),
  "provider" varchar(50),
  "providerId" varchar(255),
  "status" varchar(50),
  "eventType" varchar(50),
  "message" text,
  "created" timestamp,
  "resolved" smallint
);

CREATE TABLE IF NOT EXISTS "fundDonations" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "donationId" char(11),
  "fundId" char(11),
  "amount" double precision
);

CREATE TABLE IF NOT EXISTS "funds" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "name" varchar(50),
  "removed" boolean,
  "productId" varchar(50),
  "taxDeductible" boolean
);

CREATE TABLE IF NOT EXISTS "gatewayPaymentMethods" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11) NOT NULL,
  "gatewayId" char(11) NOT NULL,
  "customerId" varchar(255) NOT NULL,
  "externalId" varchar(255) NOT NULL,
  "methodType" varchar(50),
  "displayName" varchar(255),
  "metadata" json,
  "createdAt" timestamp,
  "updatedAt" timestamp
);

CREATE TABLE IF NOT EXISTS "gateways" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "provider" varchar(50),
  "publicKey" varchar(255),
  "privateKey" varchar(255),
  "webhookKey" varchar(255),
  "productId" varchar(255),
  "payFees" boolean,
  "currency" varchar(10),
  "settings" json,
  "environment" varchar(50),
  "createdAt" timestamp,
  "updatedAt" timestamp
);

CREATE TABLE IF NOT EXISTS "settings" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "keyName" varchar(255),
  "value" text,
  "public" boolean
);

CREATE TABLE IF NOT EXISTS "subscriptionFunds" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" varchar(11) NOT NULL,
  "subscriptionId" varchar(255),
  "fundId" char(11),
  "amount" double precision
);

CREATE TABLE IF NOT EXISTS "subscriptions" (
  "id" varchar(255) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "personId" char(11),
  "customerId" varchar(255)
);


-- =============================================================================
-- MODULE: messaging
-- =============================================================================
SET search_path TO messaging, public;

CREATE TABLE IF NOT EXISTS "blockedIps" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "conversationId" char(11),
  "serviceId" char(11),
  "ipAddress" varchar(45)
);

CREATE TABLE IF NOT EXISTS "connections" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "conversationId" char(11),
  "personId" char(11),
  "displayName" varchar(45),
  "timeJoined" timestamp,
  "socketId" varchar(45),
  "ipAddress" varchar(45)
);

CREATE TABLE IF NOT EXISTS "conversations" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "contentType" varchar(45),
  "contentId" varchar(255),
  "title" varchar(255),
  "dateCreated" timestamp,
  "groupId" char(11),
  "visibility" varchar(45),
  "firstPostId" char(11),
  "lastPostId" char(11),
  "postCount" integer,
  "allowAnonymousPosts" boolean
);

CREATE TABLE IF NOT EXISTS "deliveryLogs" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "personId" char(11),
  "contentType" varchar(20),
  "contentId" char(11),
  "deliveryMethod" varchar(10),
  "success" boolean,
  "errorMessage" varchar(500),
  "deliveryAddress" varchar(255),
  "attemptTime" timestamp
);

CREATE TABLE IF NOT EXISTS "deviceContents" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "deviceId" char(11),
  "contentType" varchar(45),
  "contentId" char(11)
);

CREATE TABLE IF NOT EXISTS "devices" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "appName" varchar(20),
  "deviceId" varchar(45),
  "churchId" char(11),
  "personId" char(11),
  "fcmToken" varchar(255),
  "label" varchar(45),
  "registrationDate" timestamp,
  "lastActiveDate" timestamp,
  "deviceInfo" text,
  "admId" varchar(255),
  "pairingCode" varchar(45),
  "ipAddress" varchar(45),
  "contentType" varchar(45),
  "contentId" char(11)
);

CREATE TABLE IF NOT EXISTS "emailTemplates" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11) NOT NULL,
  "name" varchar(255) NOT NULL,
  "subject" varchar(500) NOT NULL,
  "htmlContent" text NOT NULL,
  "category" varchar(100),
  "dateCreated" timestamp,
  "dateModified" timestamp
);

CREATE TABLE IF NOT EXISTS "messages" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "conversationId" char(11),
  "displayName" varchar(45),
  "timeSent" timestamp,
  "messageType" varchar(45),
  "content" text,
  "personId" char(11),
  "timeUpdated" timestamp
);

CREATE TABLE IF NOT EXISTS "notificationPreferences" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "personId" char(11),
  "allowPush" boolean,
  "emailFrequency" varchar(10)
);

CREATE TABLE IF NOT EXISTS "notifications" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "personId" char(11),
  "contentType" varchar(45),
  "contentId" char(11),
  "timeSent" timestamp,
  "isNew" boolean,
  "message" text,
  "link" varchar(100),
  "deliveryMethod" varchar(10),
  "triggeredByPersonId" char(11)
);

CREATE TABLE IF NOT EXISTS "privateMessages" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "fromPersonId" char(11),
  "toPersonId" char(11),
  "conversationId" char(11),
  "notifyPersonId" char(11),
  "deliveryMethod" varchar(10)
);

CREATE TABLE IF NOT EXISTS "sentTexts" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11) NOT NULL,
  "groupId" char(11),
  "recipientPersonId" char(11),
  "senderPersonId" char(11),
  "message" varchar(1600),
  "recipientCount" integer DEFAULT 0,
  "successCount" integer DEFAULT 0,
  "failCount" integer DEFAULT 0,
  "timeSent" timestamp
);

CREATE TABLE IF NOT EXISTS "textingProviders" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11) NOT NULL,
  "provider" varchar(50) NOT NULL,
  "apiKey" varchar(500),
  "apiSecret" varchar(500),
  "fromNumber" varchar(20),
  "enabled" boolean
);


-- =============================================================================
-- MODULE: doing
-- =============================================================================
SET search_path TO doing, public;

CREATE TABLE IF NOT EXISTS "actions" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "automationId" char(11),
  "actionType" varchar(45),
  "actionData" text
);

CREATE TABLE IF NOT EXISTS "assignments" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "positionId" char(11),
  "personId" char(11),
  "status" varchar(45),
  "notified" timestamp
);

CREATE TABLE IF NOT EXISTS "automations" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "title" varchar(45),
  "recurs" varchar(45),
  "active" boolean
);

CREATE TABLE IF NOT EXISTS "blockoutDates" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "personId" char(11),
  "startDate" date,
  "endDate" date
);

CREATE TABLE IF NOT EXISTS "conditions" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "conjunctionId" char(11),
  "field" varchar(45),
  "fieldData" text,
  "operator" varchar(45),
  "value" varchar(45),
  "label" varchar(255)
);

CREATE TABLE IF NOT EXISTS "conjunctions" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "automationId" char(11),
  "parentId" char(11),
  "groupType" varchar(45)
);

CREATE TABLE IF NOT EXISTS "contentProviderAuths" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "ministryId" char(11),
  "providerId" varchar(50),
  "accessToken" text,
  "refreshToken" text,
  "tokenType" varchar(50),
  "expiresAt" timestamp,
  "scope" varchar(255)
);

CREATE TABLE IF NOT EXISTS "notes" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "contentType" varchar(50),
  "contentId" char(11),
  "noteType" varchar(50),
  "addedBy" char(11),
  "createdAt" timestamp,
  "updatedAt" timestamp,
  "contents" text
);

CREATE TABLE IF NOT EXISTS "planItems" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "planId" char(11),
  "parentId" char(11),
  "sort" real,
  "itemType" varchar(45),
  "relatedId" char(11),
  "label" varchar(100),
  "description" varchar(1000),
  "seconds" integer,
  "link" varchar(1000),
  "providerId" varchar(50),
  "providerPath" varchar(500),
  "providerContentPath" varchar(50),
  "thumbnailUrl" varchar(1024)
);

CREATE TABLE IF NOT EXISTS "plans" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "ministryId" char(11),
  "planTypeId" char(11),
  "name" varchar(45),
  "serviceDate" date,
  "notes" text,
  "serviceOrder" boolean,
  "contentType" varchar(50),
  "contentId" char(11),
  "providerId" varchar(50),
  "providerPlanId" varchar(100),
  "providerPlanName" varchar(255),
  "signupDeadlineHours" integer,
  "showVolunteerNames" boolean
);

CREATE TABLE IF NOT EXISTS "planTypes" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "ministryId" char(11),
  "name" varchar(255)
);

CREATE TABLE IF NOT EXISTS "positions" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "planId" char(11),
  "categoryName" varchar(45),
  "name" varchar(45),
  "count" integer,
  "groupId" char(11),
  "allowSelfSignup" boolean,
  "description" text
);

CREATE TABLE IF NOT EXISTS "tasks" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "taskNumber" integer,
  "taskType" varchar(45),
  "dateCreated" timestamp,
  "dateClosed" timestamp,
  "associatedWithType" varchar(45),
  "associatedWithId" char(11),
  "associatedWithLabel" varchar(45),
  "createdByType" varchar(45),
  "createdById" char(11),
  "createdByLabel" varchar(45),
  "assignedToType" varchar(45),
  "assignedToId" char(11),
  "assignedToLabel" varchar(45),
  "title" varchar(255),
  "status" varchar(45),
  "automationId" char(11),
  "conversationId" char(11),
  "data" text
);

CREATE TABLE IF NOT EXISTS "times" (
  "id" char(11) NOT NULL PRIMARY KEY,
  "churchId" char(11),
  "planId" char(11),
  "displayName" varchar(45),
  "startTime" timestamp,
  "endTime" timestamp,
  "teams" varchar(1000)
);
