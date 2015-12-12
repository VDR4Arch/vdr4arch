/*
 * boblight
 * Copyright (C) Bob  2009 
 * 
 * boblight is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * boblight is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef LOG
#define LOG

#include <string>

//this has to be a macro, because we want __PRETTY_FUNCTION__
#define Log(fmt, ...) PrintLog(fmt, __PRETTY_FUNCTION__, false, ##__VA_ARGS__)
#define LogError(fmt, ...) PrintLog(fmt, __PRETTY_FUNCTION__, true, ##__VA_ARGS__)

void PrintLog (const char* fmt, const char* function, bool error, ...) __attribute__ ((format (printf, 1, 4)));
void SetLogFile(std::string logfile);

extern bool logtostderr;
extern bool printlogtofile;

#endif //LOG
