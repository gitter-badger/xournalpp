/*
 * Xournal Extended
 *
 * Part of the Xournal shape recognizer
 *
 * @author Xournal Team
 * http://xournal.sf.net
 *
 * @license GPL
 */

#ifndef __INERTIA_H__
#define __INERTIA_H__

class Point;

class Inertia {
public:
	Inertia();
	virtual ~Inertia();

public:
	double centerX();
	double centerY();

	double xx();
	double xy();
	double yy();

	double rad();

	double det();

	double getMass();

	void increase(Point p1, Point p2, int coef);
	void calc(const Point * pt, int start, int end);

private:
	double mass;
	double sx;
	double sy;
	double sxx;
	double sxy;
	double syy;
};

#endif /* __INERTIA_H__ */