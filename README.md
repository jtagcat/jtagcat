Hi, pardon for having x in backlog. Welcome to my rant of "Time, I don't have the luxury of it." on oct 20, 2020. edit: it has turned in to a more of a status report, if you ask 'so what do you do', you probably get a small chunk of this.

I would want the time of 4 people, but it seems that I can only do 2, I should sleep more.

Usually, you encounter me like this:

1. Creates 10 issues or creates 10 MRs.
_a week, a month, or 6 later_
1. Yet another 2-3 workdays within one day and half brain-dead from being awake so long.

That's not great. I used to have gh open daily, but now it's more often every when I'm filing a bug.

Experience says I either reply instantly, or in 6 months. Though, submitted MRs get magically express delivery.

Here's my stale gh notifications:

![](/cpmy/notifications-oct-20-2020.png)

Here're some stats I did of tabs 'open':

![](/cpmy/slack-anonimized-tab-stonks-1-sep-28.png)
![](/cpmy/slack-anonimized-tab-stonks-2-sep-28.png)

How much time I need to close/act/etc a tab can vary. It may be 10-30s, it may be a week. For terminology, an issue/todo/tab tree means that many other items need to be opened (or split off to) to close that object

That's not all. Besides tabs, I have todos in:
 - Mailbox, main inboxes have 16 items. I'd estimate around ⅓-½ are not needy — just things I'd want to act eventually in a year or so.
 - Joplin
   - 0main — the holy todo list giving some overview.
     - oh should probably do school stuff, attempting to finish high school out of external motivation for the 2nd time, things are looking significantly better than the first time, though still, there's a high risk I'll bail for one of the job offers I get every month or so.
     - 0 freelance things to finish, a part what's actually done..
     - fully deprecate/move a node hosting a small chunk of my self-hosted stuff
     - get the r620 I have operational, and return it to k-space, around 50-70% done.. I intended to have it as my own off-site, but I decided I'll return it as fixed/operational, and use semi-managed stuff instead.
     - complete initial exploration of ff css hacks
     - Fedora: Question for the Lenovo talk: How does the lap sensor work? "if it is wobbly or not"?
     - confidential for you, qr code blog post (unsure if to publish, might be a strong business idea)
     - get a hold of the domains, dns
       - 2fa backup
       - Migrate tpl.ee to c7.ee/s + c7.ee/* or s.c7.ee.
       - List self-hosted services I have
     - disaster backups — if all of my devices with me fail, I would be looking at significant data, information, and credential loss. plan is to have it crypted with strong single factor, or possibly many backups of the 2nd factor stored at various off-sites, and distribute it to as many devices as I can. It's going to be around 10 MB, max 80 MB (as apposed by 'as many devices as I can').
     - Better self-hosting. Current problems are:
       - no backups of container images (:latest)
       - if nfs fails, the whole node is effectively frozen, including apps not using nfs
         - current solution: have 2 independent nodes
       - multiple regions, failover.. if one node is down, the whole app is down.. easy for stuff like n.c7.ee, but nextcloud? Traefik also seems to be the main restriction. It's nice to say 'ssl and on this domain' with apps, but having HA/multiple nodes as an enterprise feature isn't nice
         - I said I'll be using and developing overnode, but that is over 6 mo backlog at this point, I think there'll be a better solution by the time I get to it.
     - liquidate unneeded assets
     - go through Joplin, and gl overall larger todos. attempt to find a way to organize them in a way that I have an overview, 90% of joplin notes I have no idea what they are, everything is condensed mostly in 10 notes I use.
     - backups (I have them functioning!!)
       - get an off-site backup for k-space stuff (problem: no cash on a monthly basis), gsuite, current, is not the best ..if you call it a solution rather than a hack
       - monitoring for backups to k-space
     - more monitoring for self-hosted apps
     - get, and use a wiki
     - pinephone, and other mobile stuff — there's a lot, lot lot here.. from building a pbx to simple automations
     - more telemetry of self — what allows me to reflect and do statistics, graphs
     - finish k-space wiki migrations
     - write a thing managing blades at k-space, the info and perms system hp provides is quite frankly thought out by an idiot (execution is somewhat better, but still)
     - qwerty, without doing any specific stuff, 80-100wpm is nice, but any non-letter/number stuff like `{}\`` and more take way too long to type.. colemak seems to be a sane solution, but I do 5-10wpm, what at the point of thinking at 150-250wpm is not satisfactory at all ;; finding qmk, but on software level would be very nice.. ahk is not available for linux, other things I haven't had the chance to look in to.. I have a keyboard running on qmk, but I haven't taken the time to make benefit of it (also I don't always have a mech kb, I have softw)
     - organize the remaining ff bookmarks (other than the visible bookmarks bar, and 'typein' (things I know, and can access by searching for them), bookmarks are almost useless.. you could argue, that I am using tabs as bookmarks, but I don't feel they are the same
     - buy pens, am out of them
     - make a kali installation on a separate ssd, idk about how I would access my other stuff if I will need them on CTFs.
     - audit wardrobe — there's no backup for daily pants, ⅓ of the shirts seem to be just gone, main and secondary hoodie would also be nice, or some hybrid of something that can show the t-shirt below.. shroud neck / having a built-in scarf is quite a must
     - distro hopping v3..
     - get a hw upgrade — current is just frankly not satisfactory
     - surface (more open) / ipad + pen for digital notes: no idea if allowed at sch, but the current implementation I have on paper doesn't cut it, flipping out a laptop doesn't always work, and sometimes I don't have the time to find that character I don't have the name of (otherwise, I'm quite good at using unicode to my advantage)
     - find a doc I was referred to, book a time
 - Thunderbird, the second profile, RSS/Atom/JSON/XML/etc web feeds.
   - Social medias, Twitter, Instagram, Youtube, and Reddit arrive via feeds. They are heavily filtered and sorted.
   - Of the hundreds of feeds, I would highlight:
     - jlelse
     - Beaker
     - Mango PDF
     - Privacytools
     - Linuxserver
     - Fedora Magazine
     - GitLab
     - StackOverflow
     - Microsoft Research
- GitHub, as mentioned before.
 - GitLab, also personal:
   - Overall larger todos, 261/308 issues open.
   - Ideas, partial migration from Joplin, 15 open.
   - Spotify, as determined by distro-hopping, the best service accounting my use-case (Tidal being 2nd, also not accounting self-hosted stuff) doesn't provide great exploration. I created a system what works significantly better. I'm 52/1045 there, the larger number goes up around 0.5-1 times daily, the first number goes up 1-3 times weekly. Doing this by hand in GL issues, but there's a todo to build a huge app managing all this.
 - In Linux, everything is files. There's much to be found here:
   - The downloads folder. In total 12 objects of interest/action.
   - ~/c aka cloud. For backups, I approach it with rather 'this is cloud, and I have a cache of it (662,4 GiB)'. Recovery has been much easier. (Other directories do get backed up by restic, at least hourly, some every 10 minutes (tb and ff)).
     - If not already marked as a thing to do above, git repos.
     - m2, version 2 of 'machine' directory. Stuff I've written for better operation. There're scripts, larger shell aliases/functions, there's config files, there's even a reduced app node in there (for example, n.c7.ee is also available on ip6-localhost, speeds stuff up significantly).
     - The holy `warm`, the main daily data store.
       - Media I haven't consumed:
         - Audiobooks
         - e-books
         - Infinite number of talks, panels, screencasts, presentations, guides, etc.
           - CommCon
           - Defcon
           - GitLab
           - Disobey
           - ENISA
           - GovInsider
           - PurpleCon
           - Fedora
           - Indie Worldwide (highly likely I'll drop it)
           - Ubuntu
           - Oxidize
           - Web Audio Conf
           - You got this Conf
           - !!Con
           - Michigan!/usr/group
           - https://www.facebook.com/riigiinfosysteemiamet/videos
           - Rustconf
           - Kubecon
           - Level1Techs
           - FinSec
           - The list changes on a weekly/monthly basis
         - Anime
         - VODs of https://twitch.tv/tennysonmusic
         - warm/income — a modest directory with 9204 files looking to be actioned on, absorbed, or found a permanent home in the archives or quick reference (warm/store).
           - of which, 8223 are files from previous accounts, organizations, more.
       - 8 unfinished/-started projects / objects of interest.
   - whatever else you may find, I hate there being tons of untracked dotfiles..
 - There's also physical items representing things needy of completion:
   - Exhibit A, books. I carry one with me daily as a solid backup for "if all else more needy fail". So far, I haven't opened it. At least I tried.
   - There's around 10 projects / objects of interest waiting.

So this reflection gave me a better overview for myself well, thanks. Should probably proceed to drink, eat, and sleep for the first time today.

***

Ah yes, something in the style of a CV: (attempt 6 or 8 (probably 6, since brain is more likely rounding to powers of 2)
 - Active member of K-Space. Moved far away, thus haven't had the chance to participate as actively. The times I do visit, things get done swiftly due to prior systematization and goals.
 - Thing I choose to hide due to privacy.
 - 4-6 things I can't tell you about.
 - Things I don't remember. Not having a reason to remember things irrelevant at the time is quite a factor. I don't exactly remember what I did today.
 - Things not relevant.

### CTFs
1. Persistent tester for Rangeforce's Cyber Sieges. Frequently blue teaming, there have been some red teaming. Usually get about half or more of the things secured. Have also gone off-mission, tooling myself, as no significant pressure is present.
1. Kübernaaskel 2020 tester. Red team. Got a few flags, don't remember if first or second within the small group. Didn't feel smart.
1. First place on Cyber Arch's Telia CTF 2020 with team Compose+Duck+No, the second team of DuckDuckNo. I understood the challenges, and strived towards getting flags. Didn't personally capture any flags, but assisted the team, while sometimes intentionally obvious, other times not, spying on DDN. Credit for flags and swift execution goes to @raoz.

### Things people have told me to list
 - Sysadmin skills
   - I don't really know what people mean by this. I'll just say I've
 - Docker
   - Working with pre-made containers. Hooking them up, troubleshooting, since Early 2018, late 2017, I think?
   - Writing Dockerfiles. Out of own need to have it to have everything hosted in one place — convenience, somewhat more secure, for the occasions there's some horrible thing with horrible dependencies, that only works on x, but x has y what is not acceptable, and something from somewhere else. Since q1 or q2 of 2020.
   - General shitstorm.
 - Static sites.

### Things I guess myself, are nice to list
 - Git.. I can do a lot, but I still feel there're things I could do better, as some things seem with sanity too time-intensive. Usage since 2016-2017 I think? Not sure at all. Since 2019, have gone further than (fork,) clone, checkout, edit thing, add, commit, push. If anything went slightly wrong, I copy-pastad to an another file and nuked the whole thing, starting fresh from git clone.
 - In-depth knowledge about a wide range of tech. Ability to discuss how something is best done, finding superior solutions.

Help, what else have I done? I can't remember!

<!--
**jtagcat/jtagcat** is a ✨ _special_ ✨ repository because its `README.md` (this file) appears on your GitHub profile.

Here are some ideas to get you started:

- 🔭 I’m currently working on ...
- 🌱 I’m currently learning ...
- 👯 I’m looking to collaborate on ...
- 🤔 I’m looking for help with ...
- 💬 Ask me about ...
- 📫 How to reach me: ...
- 😄 Pronouns: ...
- ⚡ Fun fact: ...
-->

***

A status update may be found on [c7](//www.c7.ee/status/2020-11-09/).