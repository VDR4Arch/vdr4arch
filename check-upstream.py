#!/usr/bin/python3

#   VDR4Arch upstream check script
#   Copyright (C) 2023 Manuel Reimer <manuel.reimer@gmx.de>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.

import urllib.request
import re

# Packages to check
PACKAGES = [
    ["irctl", "github"],
    ["minisatip", "github"],
    ["t2scan", "github"],
    ["vdradmin-am", "github"],
    ["vdr-epg-daemon", "github"],
    ["w_scan_cpp", "github"],
    ["w_scan2", "github"],
    ["deps/cxxtools", "github"],
    ["deps/graphlcd-base", "github"],
    ["deps/libnetceiver", "github"],
    ["deps/librepfunc", "github"],
    ["deps/tntdb", "github"],
    ["deps/tntnet", "github"],
    ["plugins/vdr-bgprocess", "github"],
    ["plugins/vdr-burn", "github"],
    ["plugins/vdr-chanman", "github"],
    ["plugins/vdr-channellists", "github"],
    ["plugins/vdr-channelscan", "github"],
    ["plugins/vdr-cinebars", "github"],
    ["plugins/vdr-dbus2vdr", "github"],
    ["plugins/vdr-ddci2", "github"],
    ["plugins/vdr-devstatus", "gitlab"],
    ["plugins/vdr-dfatmo", "github"],
    ["plugins/vdr-duplicates", "github"],
    ["plugins/vdr-dvbapi", "github"],
    ["plugins/vdr-eepg", "github"],
    ["plugins/vdr-epg2vdr", "github"],
    ["plugins/vdr-epgborder", "github"],
#    ["plugins/vdr-epgfixer", "github"],
    ["plugins/vdr-epgsearch", "github"],
    ["plugins/vdr-epgsync", "github"],
    ["plugins/vdr-extrecmenung", "gitlab"],
    ["plugins/vdr-favorites", "github"],
    ["plugins/vdr-femon", "github"],
    ["plugins/vdr-filebrowser", "github"],
    ["plugins/vdr-fritzbox", "github"],
    ["plugins/vdr-gamepad", "github"],
    ["plugins/vdr-graphlcd", "github"],
    ["plugins/vdr-imonlcd", "github"],
    ["plugins/vdr-iptv", "github"],
    ["plugins/vdr-lcdproc", "github"],
    ["plugins/vdr-live", "github"],
    ["plugins/vdr-markad", "github"],
    ["plugins/vdr-mcli", "github"],
    ["plugins/vdr-mp3", "github"],
    ["plugins/vdr-mpv", "github"],
    ["plugins/vdr-osd2web", "github"],
    ["plugins/vdr-osdteletext", "github"],
    ["plugins/vdr-plex", "github"],
    ["plugins/vdr-radio", "github"],
    ["plugins/vdr-recsearch", "github"],
    ["plugins/vdr-remoteosd", "github"],
    ["plugins/vdr-restfulapi", "github"],
    ["plugins/vdr-rpihddevice", "github"],
    ["plugins/vdr-rssreader", "github"],
    ["plugins/vdr-satip", "github"],
    ["plugins/vdr-scraper2vdr", "github"],
    ["plugins/vdr-skindesigner", "gitlab"],
    ["plugins/vdr-skinenigmang", "github"],
    ["plugins/vdr-skinflat", "github"],
    ["plugins/vdr-skinflatplus", "github"],
    ["plugins/vdr-skinpearlhd", "github"],
    ["plugins/vdr-skinsoppalusikka", "github"],
    ["plugins/vdr-sleeptimer", "github"],
    ["plugins/vdr-softhdcuvid", "github"],
    ["plugins/vdr-softhddevice", "github"],
    ["plugins/vdr-streamdev", "github"],
    ["plugins/vdr-svdrposd", "github"],
    ["plugins/vdr-svdrpservice", "github"],
    ["plugins/vdr-systeminfo", "github"],
    ["plugins/vdr-targavfd", "github"],
    ["plugins/vdr-tvguide", "gitlab"],
    ["plugins/vdr-tvguideng", "gitlab"],
    ["plugins/vdr-tvscraper", "github"],
    ["plugins/vdr-vdrmanager", "github"],
    ["plugins/vdr-vdrtva", "github"],
    ["plugins/vdr-vnsiserver", "github"],
    ["plugins/vdr-weatherforecast", "github"],
    ["plugins/vdr-wirbelscan", "github"],
    ["plugins/vdr-xmltv2vdr", "github"],
    ["plugins/vdr-zaphistory", "github"],
    ["plugins/vdr-zappilot", "github"]
]


# Simple .SRCINFO parser
def parse_srcinfo(path):
    result = {"source": []}
    file = open(path, "r")
    for line in file:
        parts = line.strip().split(" = ")
        if len(parts) != 2:
            break

        name, value = parts
        if name in ["pkgbase", "pkgver"]:
            result[name] = value
        if name == "source":
            result["source"].append(value)

    return result


# Get latest version of a GitHub project without using their API
def get_github_version(source):
    projecturl = "/".join(source.split("/", 5)[:-1])
    tagsurl = f"{projecturl}/tags"
    text = urllib.request.urlopen(tagsurl).read().decode("utf-8")
    versions = re.findall(r'<a href=".+?/tag/([^"]+)', text)
    latest = versions[0].replace("v", "").replace("V", "")
    return latest

# Get latest version of a GitLab project without using their API
def get_gitlab_version(source):
    projecturl = "/".join(source.split("/", 5)[:-1])
    tagsurl = f"{projecturl}/-/tags?format=atom"
    text = urllib.request.urlopen(tagsurl).read().decode("utf-8")
    versions = re.findall(r'<title>([^<]+)', text)
    latest = versions[1].replace("v", "").replace("V", "")
    return latest

# Get latest version of a BitBucket project without using their API
def get_bitbucket_version(source):
    projecturl = "/".join(source.split("/", 5)[:-1])
    tagsurl = f"{projecturl}/downloads/?tab=tags"
    text = urllib.request.urlopen(tagsurl).read().decode("utf-8")
    versions = re.findall(r'<td class="name">([^<]+)', text)
    latest = versions[0].replace("v", "").replace("V", "")
    return latest

def main():
    for package in PACKAGES:
        path, host = package
        srcinfo = parse_srcinfo(f"{path}/.SRCINFO")
        source = srcinfo["source"][0]
        if "::" in source:
            source = source.split("::")[1]

        if host == "github":
            version = get_github_version(source)
        elif host == "gitlab":
            version = get_gitlab_version(source)
        elif host == "bitbucket":
            version = get_bitbucket_version(source)
        # TODO: Add more hosting platforms
        else:
            raise Exception()

        status = "OK"
        if version != srcinfo["pkgver"]:
            status = f"Local: {srcinfo['pkgver']} Upstream: {version}"
        print(srcinfo["pkgbase"], status)


if __name__ == "__main__":
    main()
